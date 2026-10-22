/// Which part of the version a release bumps.
///
/// Every kind also raises the build number by one: the build number is the
/// Android `versionCode`, and a phone only accepts an in-place update when the
/// new build's `versionCode` is higher than the installed one.
enum BumpKind { build, patch, minor, major }

/// The app version in `pubspec.yaml`: `major.minor.patch+build`.
///
/// Pure Dart (no Flutter imports) so the `tool/app_version.dart` command line
/// tool, the app and the tests share one implementation.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, this.build);

  final int major;
  final int minor;
  final int patch;

  /// Android `versionCode` / iOS build number. Must only ever increase.
  final int build;

  static final RegExp _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)\+(\d+)$');

  /// Android stores `versionCode` as a signed 32-bit integer.
  static const int maxAndroidVersionCode = 2100000000;

  /// Parses `1.2.3+4`; null when it is not exactly that shape.
  static AppVersion? tryParse(String text) {
    final m = _pattern.firstMatch(text.trim());
    if (m == null) return null;
    return AppVersion(
      int.parse(m[1]!),
      int.parse(m[2]!),
      int.parse(m[3]!),
      int.parse(m[4]!),
    );
  }

  factory AppVersion.parse(String text) {
    final v = tryParse(text);
    if (v == null) {
      throw FormatException(
        'Expected "major.minor.patch+build" (for example 1.2.3+4)',
        text,
      );
    }
    return v;
  }

  /// The version name users see: `1.2.3`.
  String get name => '$major.$minor.$patch';

  /// The one display form used everywhere in the app: `1.2.3 (4)`.
  String get label => '$name ($build)';

  /// True when [build] is usable as an Android `versionCode`.
  bool get isValidAndroidVersionCode =>
      build > 0 && build <= maxAndroidVersionCode;

  /// The next release version. The build number always rises by one.
  AppVersion bump(BumpKind kind) {
    switch (kind) {
      case BumpKind.build:
        return AppVersion(major, minor, patch, build + 1);
      case BumpKind.patch:
        return AppVersion(major, minor, patch + 1, build + 1);
      case BumpKind.minor:
        return AppVersion(major, minor + 1, 0, build + 1);
      case BumpKind.major:
        return AppVersion(major + 1, 0, 0, build + 1);
    }
  }

  /// Orders by version name, then build number.
  @override
  int compareTo(AppVersion other) {
    for (final pair in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
      (build, other.build),
    ]) {
      if (pair.$1 != pair.$2) return pair.$1.compareTo(pair.$2);
    }
    return 0;
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >(AppVersion other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  String toString() => '$name+$build';

  // `(\r?)` keeps a CRLF pubspec's line ending intact when the line is replaced.
  static final RegExp _pubspecLine = RegExp(
    r'^version:[ \t]*(\S+)[ \t]*(\r?)$',
    multiLine: true,
  );

  /// The `version:` value of a pubspec's text, or null when absent/malformed.
  static AppVersion? fromPubspec(String pubspecText) {
    final m = _pubspecLine.firstMatch(pubspecText);
    return m == null ? null : tryParse(m[1]!);
  }

  /// [pubspecText] with its `version:` line replaced by [version]; every other
  /// byte (comments, line endings) is left as it was.
  static String replaceInPubspec(String pubspecText, AppVersion version) {
    if (!_pubspecLine.hasMatch(pubspecText)) {
      throw const FormatException('pubspec.yaml has no "version:" line');
    }
    return pubspecText.replaceFirstMapped(
      _pubspecLine,
      (m) => 'version: $version${m[2]}',
    );
  }
}
