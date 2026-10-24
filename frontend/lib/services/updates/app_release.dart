import '../../utils/app_version.dart';

/// One app build published as a GitHub release of the public releases
/// repository ([AppUpdateService.releasesRepo]).
///
/// CI tags app builds `app-vX.Y.Z+N` (N is the Android `versionCode`); any
/// other tag (`catalog-*`) is not an app build and is ignored here.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.pageUrl,
    this.apkUrl,
    this.notes = const [],
  });

  final AppVersion version;

  /// What changed in this build, one line per item, taken from the release
  /// description (CI copies the CHANGELOG entry there). Headings such as
  /// "### Fixed" are kept as their own lines; Markdown markup is removed.
  final List<String> notes;

  /// The release's page on GitHub.
  final Uri pageUrl;

  /// The release's APK download, when it has one.
  final Uri? apkUrl;

  /// What "Update" opens: the APK itself (the browser downloads it and Android's
  /// installer takes over), or the release page when there is no APK asset.
  Uri get updateUrl => apkUrl ?? pageUrl;

  static final RegExp _tagPattern = RegExp(r'^app-v(\d+\.\d+\.\d+\+\d+)$');

  /// The version in an `app-vX.Y.Z+N` tag; null for any other tag.
  static AppVersion? versionFromTag(String tag) {
    final m = _tagPattern.firstMatch(tag.trim());
    return m == null ? null : AppVersion.tryParse(m[1]!);
  }

  /// One release object from the GitHub releases API. Null when it is not a
  /// published app build (draft, pre-release, other tag) or is malformed.
  static AppRelease? fromJson(Object? json) {
    if (json is! Map) return null;
    if (json['draft'] == true || json['prerelease'] == true) return null;
    final tag = json['tag_name'];
    final page = json['html_url'];
    if (tag is! String || page is! String) return null;
    final version = versionFromTag(tag);
    final pageUrl = _githubUri(page);
    if (version == null || pageUrl == null) return null;
    return AppRelease(
      version: version,
      pageUrl: pageUrl,
      apkUrl: _apkUrl(json['assets']),
      notes: notesFrom(json['body']),
    );
  }

  /// Most lines shown; a long changelog is cut, the release page has it all.
  static const int maxNoteLines = 24;

  /// The release description as plain lines: headings without "#", list
  /// items without "-"/"*", links reduced to their text, empty lines and
  /// HTML comments dropped, the signing/build footer left out.
  static List<String> notesFrom(Object? body) {
    if (body is! String) return const [];
    final lines = <String>[];
    for (final raw in body.split(RegExp(r'\r?\n'))) {
      var line = raw.trim();
      if (line.isEmpty || line.startsWith('<!--')) continue;
      if (line.startsWith('Signed with ') || line.startsWith('Built by ')) {
        continue;
      }
      line = line
          .replaceFirst(RegExp(r'^#+\s*'), '')
          .replaceFirst(RegExp(r'^[-*]\s+'), '• ')
          .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!)
          .replaceAll(RegExp(r'[*_`]'), '');
      if (line.trim().isEmpty) continue;
      lines.add(line);
      if (lines.length == maxNoteLines) break;
    }
    return lines;
  }

  /// The newest app build in a GitHub releases list (`GET /releases`), by
  /// build number. Null when the list holds none.
  static AppRelease? newestOf(Object? json) {
    if (json is! List) return null;
    AppRelease? newest;
    for (final item in json) {
      final release = fromJson(item);
      if (release == null) continue;
      if (newest == null || release.version.build > newest.version.build) {
        newest = release;
      }
    }
    return newest;
  }

  /// ABI-specific splits only install on matching phones, so a universal APK
  /// is preferred when a release carries both.
  static final RegExp _abiSplit = RegExp(
    r'arm64|armeabi|x86',
    caseSensitive: false,
  );

  static Uri? _apkUrl(Object? assets) {
    if (assets is! List) return null;
    Uri? split;
    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = asset['name'];
      final url = asset['browser_download_url'];
      if (name is! String || url is! String) continue;
      if (!name.toLowerCase().endsWith('.apk')) continue;
      final uri = _githubUri(url);
      if (uri == null) continue;
      if (!_abiSplit.hasMatch(name)) return uri;
      split ??= uri;
    }
    return split;
  }

  /// Only https links on github.com are opened from a release.
  static Uri? _githubUri(String text) {
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'https') return null;
    if (uri.host != 'github.com' && !uri.host.endsWith('.github.com')) {
      return null;
    }
    return uri;
  }
}
