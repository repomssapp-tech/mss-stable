// App version control: one source of truth (pubspec.yaml `version:`), a
// predictable bump, and a guard that keeps builds installable over each other.
//
//   dart run tool/app_version.dart show
//   dart run tool/app_version.dart bump build|patch|minor|major
//   dart run tool/app_version.dart check [--against <git-ref>]
//                                        [--against-latest-tag <prefix>]
//                                        [--require-increase]
//
// A phone only updates an installed app in place when the new APK has the same
// applicationId, is signed with the same key, and carries a HIGHER Android
// versionCode (the number after the "+"). `check` fails when the build number is
// malformed, or lower than the one it is compared with; with --require-increase
// it also fails when it is merely equal. See docs/APP_VERSIONING.md.
import 'dart:io';

import 'package:frontend/utils/app_version.dart';

const _pubspecPath = 'pubspec.yaml';

Never _fail(String message) {
  stderr.writeln('app_version: $message');
  exit(1);
}

AppVersion _current() {
  final file = File(_pubspecPath);
  if (!file.existsSync()) {
    _fail('run this from the frontend/ directory ($_pubspecPath not found)');
  }
  final v = AppVersion.fromPubspec(file.readAsStringSync());
  if (v == null) {
    _fail('$_pubspecPath has no valid "version: major.minor.patch+build" line');
  }
  return v;
}

String _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    _fail('git ${args.join(' ')} failed: ${(result.stderr as String).trim()}');
  }
  return (result.stdout as String).trim();
}

AppVersion _versionAtRef(String ref) {
  final text = _git(['show', '$ref:frontend/$_pubspecPath']);
  final v = AppVersion.fromPubspec(text);
  if (v == null) _fail('$ref has no valid version in frontend/$_pubspecPath');
  return v;
}

/// Highest version among tags named `<prefix><major.minor.patch+build>`.
AppVersion? _latestTagVersion(String prefix) {
  AppVersion? best;
  for (final line in _git(['tag', '--list', '$prefix*']).split('\n')) {
    final tag = line.trim();
    if (!tag.startsWith(prefix)) continue;
    final v = AppVersion.tryParse(tag.substring(prefix.length));
    if (v != null && (best == null || v > best)) best = v;
  }
  return best;
}

void main(List<String> args) {
  if (args.isEmpty) {
    _fail('usage: show | bump <build|patch|minor|major> | check [options]');
  }
  switch (args.first) {
    case 'show':
      final v = _current();
      stdout.writeln('$v  (versionName ${v.name}, versionCode ${v.build})');
    case 'bump':
      if (args.length < 2) _fail('bump needs: build | patch | minor | major');
      final kind = BumpKind.values.where((k) => k.name == args[1]).firstOrNull;
      if (kind == null) _fail('unknown bump kind "${args[1]}"');
      final before = _current();
      final after = before.bump(kind);
      final file = File(_pubspecPath);
      file.writeAsStringSync(
        AppVersion.replaceInPubspec(file.readAsStringSync(), after),
      );
      stdout.writeln('$before -> $after');
    case 'check':
      _check(args.skip(1).toList());
    default:
      _fail('unknown command "${args.first}"');
  }
}

void _check(List<String> options) {
  String? against;
  String? tagPrefix;
  var requireIncrease = false;
  for (var i = 0; i < options.length; i++) {
    switch (options[i]) {
      case '--against':
        against = options[++i];
      case '--against-latest-tag':
        tagPrefix = options[++i];
      case '--require-increase':
        requireIncrease = true;
      default:
        _fail('unknown option "${options[i]}"');
    }
  }

  final v = _current();
  if (!v.isValidAndroidVersionCode) {
    _fail(
      'build number ${v.build} is not a usable Android versionCode '
      '(1..${AppVersion.maxAndroidVersionCode})',
    );
  }
  stdout.writeln('version ${v.name}, versionCode ${v.build}: valid');

  final comparisons = <String, AppVersion>{};
  if (against != null) comparisons[against] = _versionAtRef(against);
  if (tagPrefix != null) {
    final tagged = _latestTagVersion(tagPrefix);
    if (tagged != null) comparisons['latest $tagPrefix tag'] = tagged;
  }

  var ok = true;
  comparisons.forEach((label, base) {
    if (v.build < base.build) {
      stderr.writeln(
        'FAIL: versionCode ${v.build} is lower than $label ($base). A phone '
        'running that build would refuse this one as a downgrade.',
      );
      ok = false;
    } else if (v.build == base.build) {
      if (requireIncrease) {
        stderr.writeln(
          'FAIL: versionCode ${v.build} equals $label ($base); a release must '
          'raise it (dart run tool/app_version.dart bump build).',
        );
        ok = false;
      } else {
        stdout.writeln('note: same versionCode as $label ($base)');
      }
    } else {
      stdout.writeln(
        'ok: ${v.build} is higher than $label ($base): installs as an update',
      );
    }
  });
  if (!ok) exit(1);
}
