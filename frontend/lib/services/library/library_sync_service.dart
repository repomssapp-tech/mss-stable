import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../account/app_session.dart';
import '../network/api_exception.dart';
import '../network/debouncer.dart';
import '../network/request_manager.dart';
import 'library_api_service.dart';

/// The device-side saved library that [LibrarySyncService] keeps in step with
/// the server.
abstract interface class LibrarySyncHost {
  List<String> get bookmarks;
  List<String> get eligibilityIds;

  /// Replaces the local bookmarks with [ids] (persists and notifies).
  Future<void> applyRemoteBookmarks(List<String> ids);

  /// Replaces the local eligibility results with the server's set.
  Future<void> applyRemoteEligibility(List<String> ids, DateTime? savedAt);
}

/// Keeps the device's bookmarks and saved eligibility results in step with the
/// server (`/v1/me/favorites`, `/v1/me/eligibility-results`).
///
/// The device stays the working copy: every change is applied locally first and
/// works offline. The server copy exists so the library survives a new phone or
/// a second device.
///
/// * **Writes are queued and batched.** A change is recorded at once (and kept
///   across app restarts), then sent [writeDelay] later together with whatever
///   else changed. The queue is also sent when the app goes to the background
///   and when the network returns. Requests go through [RequestManager], so a
///   failing server is backed off instead of hammered.
/// * **Reads are rare.** The server copy is pulled at sign-in / start and at
///   most every [pullFreshFor] afterwards.
/// * **Merging.** The first sync of an account keeps everything: local and
///   server favorites are united and local-only ones are uploaded. After that the
///   server is authoritative, with this device's unsent changes applied on top.
/// * **Refusals.** A scheme the account may not see (404) or an invalid request
///   (400) is dropped from the queue and stays local-only. A missing profile
///   state (409) keeps the change queued for later.
/// * **Accounts.** The queue belongs to one account; another account never
///   inherits it, and sign-out forgets it.
class LibrarySyncService {
  LibrarySyncService({
    required this.host,
    LibraryApiService? api,
    RequestManager? requests,
    Duration writeDelay = const Duration(seconds: 2),
    String? Function()? ownerId,
    Future<SharedPreferences> Function()? preferences,
  }) : _api = api ?? LibraryApiService(),
       _requests = requests ?? RequestManager.instance,
       _writes = Debouncer(writeDelay),
       _ownerId = ownerId ?? (() => AppSession.instance.userId),
       _preferences = preferences ?? SharedPreferences.getInstance;

  /// The server copy is pulled at most this often.
  static const Duration pullFreshFor = Duration(minutes: 15);

  static const String _stateKey = 'library_sync_state_v1';
  static const String _writeKey = 'library_write';
  static const String _pullKey = 'library_pull';

  final LibrarySyncHost host;
  final LibraryApiService _api;
  final RequestManager _requests;
  final Debouncer _writes;
  final String? Function() _ownerId;
  final Future<SharedPreferences> Function() _preferences;

  bool _loaded = false;
  String? _owner;
  bool _initialised = false;
  final Map<String, bool> _favoriteOps = {};

  /// Saved on this device but refused by the server (400/404). Kept so the
  /// next pull doesn't drop them (issue #127: a bookmark vanished on restart).
  final Set<String> _localOnly = {};
  bool _eligibilityDirty = false;
  List<String> _eligibilityIds = [];
  String? _eligibilityEtag;

  /// Changes not yet confirmed by the server (for tests and diagnostics).
  int get pendingChanges => _favoriteOps.length + (_eligibilityDirty ? 1 : 0);

  // ── recording local changes ────────────────────────────────────────────

  /// Records that [id] is now [saved] on this device.
  Future<void> recordFavorite(String id, {required bool saved}) async {
    if (!LibraryApiService.isValidId(id)) return;
    if (!await _ensureOwner()) return;
    _favoriteOps[id] = saved;
    if (!saved) _localOnly.remove(id);
    await _persist();
    _writes.run(flush);
  }

  /// Records the new saved eligibility set of this device (`[]` clears it).
  Future<void> recordEligibility(List<String> schemeIds) async {
    if (!await _ensureOwner()) return;
    _eligibilityDirty = true;
    _eligibilityIds = schemeIds
        .where(LibraryApiService.isValidId)
        .toSet()
        .toList();
    await _persist();
    _writes.run(flush);
  }

  // ── sending ───────────────────────────────────────────────────────────

  /// Sends the queued changes now (app to background, network back).
  Future<void> flush() async {
    _writes.cancel();
    if (!await _ensureOwner()) return;
    if (pendingChanges == 0) return;
    await _requests.run<void>(_writeKey, _flushOnce);
  }

  Future<void> _flushOnce() async {
    if (!await _ensureOwner()) return;
    Object? retryable;
    for (final entry in _favoriteOps.entries.toList()) {
      try {
        if (entry.value) {
          await _api.saveFavorite(entry.key);
        } else {
          await _api.removeFavorite(entry.key);
        }
        _favoriteOps.remove(entry.key);
      } on ApiException catch (e) {
        if (e.statusCode == 400 || e.statusCode == 404) {
          // Refused for good (not visible to this account): stays local-only.
          if (entry.value) _localOnly.add(entry.key);
          _favoriteOps.remove(entry.key);
        } else if (e.statusCode == 409) {
          // Profile state missing: keep it queued, do not block the others.
          continue;
        } else {
          retryable ??= e;
          break;
        }
      } catch (e) {
        retryable ??= e;
        break;
      }
    }

    if (_eligibilityDirty && retryable == null) {
      try {
        await _pushEligibility();
      } on ApiException catch (e) {
        if (e.statusCode == 400 || e.statusCode == 404) {
          _eligibilityDirty = false;
        } else if (e.statusCode != 409) {
          retryable ??= e;
        }
      } catch (e) {
        retryable ??= e;
      }
    }

    await _persist();
    if (retryable != null) throw retryable;
  }

  Future<void> _pushEligibility() async {
    var etag = _eligibilityEtag;
    for (var attempt = 0; attempt < 2; attempt++) {
      etag ??= (await _api.getEligibility()).etag;
      try {
        final saved = await _api.putEligibility(
          _eligibilityIds,
          etag: etag ?? '"eligibility-0"',
        );
        _eligibilityEtag = saved.etag;
        _eligibilityDirty = false;
        return;
      } on ApiException catch (e) {
        // Another device wrote first. The user's newest save on this device is
        // the intent, so take the current version and write again, once.
        if (e.statusCode == 412 && attempt == 0) {
          etag = null;
          _eligibilityEtag = null;
          continue;
        }
        rethrow;
      }
    }
  }

  // ── reading ───────────────────────────────────────────────────────────

  /// Brings in the server copy and merges it. Does nothing when a recent pull is
  /// still fresh, unless [force].
  Future<void> pull({bool force = false}) async {
    if (!await _ensureOwner()) return;
    await _requests.run<void>(
      _pullKey,
      _pullOnce,
      minInterval: pullFreshFor,
      force: force,
    );
  }

  Future<void> _pullOnce() async {
    if (!await _ensureOwner()) return;
    // The server must hear this device's changes before they are merged back.
    await _flushOnce();

    final server = await _api.listAllFavorites();
    final local = host.bookmarks;
    final merged = <String>[];
    if (!_initialised) {
      // First sync of this account: lose nothing from either side.
      merged
        ..addAll(local)
        ..addAll(server.where((id) => !local.contains(id)));
      for (final id in local) {
        if (!server.contains(id) && LibraryApiService.isValidId(id)) {
          _favoriteOps[id] = true;
        }
      }
    } else {
      final remote = server.toSet();
      _favoriteOps.forEach((id, saved) {
        if (saved) {
          remote.add(id);
        } else {
          remote.remove(id);
        }
      });
      // Local-only bookmarks the server refused stay saved on this device.
      remote.addAll(local.where(_localOnly.contains));
      merged
        ..addAll(local.where(remote.contains))
        ..addAll(remote.where((id) => !local.contains(id)));
    }
    if (!_sameSet(merged, local)) await host.applyRemoteBookmarks(merged);

    final eligibility = await _api.getEligibility();
    _eligibilityEtag = eligibility.etag;
    if (!_eligibilityDirty) {
      if (eligibility.version > 0) {
        if (!_sameSet(eligibility.schemeIds, host.eligibilityIds)) {
          await host.applyRemoteEligibility(
            eligibility.schemeIds,
            eligibility.savedAt,
          );
        }
      } else if (!_initialised && host.eligibilityIds.isNotEmpty) {
        _eligibilityDirty = true;
        _eligibilityIds = host.eligibilityIds
            .where(LibraryApiService.isValidId)
            .toList();
      }
    }

    _initialised = true;
    await _persist();
    if (pendingChanges > 0) await _flushOnce();
  }

  // ── sign-out ──────────────────────────────────────────────────────────

  /// Forgets this device's sync state (sign-out, account switch).
  Future<void> reset() async {
    _writes.cancel();
    _owner = null;
    _initialised = false;
    _favoriteOps.clear();
    _localOnly.clear();
    _eligibilityDirty = false;
    _eligibilityIds = [];
    _eligibilityEtag = null;
    _loaded = true;
    _requests.invalidate(_pullKey);
    try {
      (await _preferences()).remove(_stateKey);
    } catch (e) {
      debugPrint('[LibrarySync] reset failed: $e');
    }
  }

  void dispose() => _writes.cancel();

  // ── state ─────────────────────────────────────────────────────────────

  /// Loads the saved queue for the signed-in account (and drops a queue that
  /// belongs to another one). False when nobody is signed in.
  Future<bool> _ensureOwner() async {
    final current = _ownerId();
    if (current == null) return false;
    if (!_loaded) {
      _loaded = true;
      try {
        final raw = (await _preferences()).getString(_stateKey);
        if (raw != null) {
          final json = jsonDecode(raw);
          if (json is Map && json['owner'] == current) {
            _owner = current;
            _initialised = json['initialised'] == true;
            final ops = json['favorites'];
            if (ops is Map) {
              ops.forEach((k, v) => _favoriteOps[k.toString()] = v == true);
            }
            final localOnly = json['local_only'];
            if (localOnly is List) {
              _localOnly.addAll([for (final i in localOnly) '$i']);
            }
            _eligibilityDirty = json['eligibility_dirty'] == true;
            final ids = json['eligibility_ids'];
            if (ids is List) _eligibilityIds = [for (final i in ids) '$i'];
          }
        }
      } catch (e) {
        debugPrint('[LibrarySync] could not read saved state: $e');
      }
    }
    if (_owner != current) {
      // A different account than the one the state belongs to.
      _owner = current;
      _initialised = false;
      _favoriteOps.clear();
      _localOnly.clear();
      _eligibilityDirty = false;
      _eligibilityIds = [];
      _eligibilityEtag = null;
    }
    return true;
  }

  Future<void> _persist() async {
    final owner = _owner;
    if (owner == null) return;
    try {
      await (await _preferences()).setString(
        _stateKey,
        jsonEncode({
          'owner': owner,
          'initialised': _initialised,
          'favorites': _favoriteOps,
          'local_only': _localOnly.toList(),
          'eligibility_dirty': _eligibilityDirty,
          'eligibility_ids': _eligibilityIds,
        }),
      );
    } catch (e) {
      debugPrint('[LibrarySync] could not save state: $e');
    }
  }

  static bool _sameSet(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);
}
