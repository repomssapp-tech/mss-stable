import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/app_version.dart';

void main() {
  group('AppVersion parsing', () {
    test('parses major.minor.patch+build', () {
      final v = AppVersion.parse('1.2.3+45');
      expect((v.major, v.minor, v.patch, v.build), (1, 2, 3, 45));
      expect(v.name, '1.2.3');
      expect(v.toString(), '1.2.3+45');
    });

    test('rejects anything else', () {
      for (final bad in [
        '1.2.3',
        '1.2+4',
        'v1.2.3+4',
        '1.2.3+x',
        '',
        '1.2.3+4+5',
      ]) {
        expect(AppVersion.tryParse(bad), isNull, reason: bad);
      }
      expect(() => AppVersion.parse('1.2.3'), throwsFormatException);
    });
  });

  group('bumping', () {
    const v = AppVersion(1, 2, 3, 10);
    test('every kind raises the build number by exactly one', () {
      for (final kind in BumpKind.values) {
        expect(v.bump(kind).build, 11, reason: kind.name);
      }
    });

    test('lower parts reset when a higher part is bumped', () {
      expect(v.bump(BumpKind.build).toString(), '1.2.3+11');
      expect(v.bump(BumpKind.patch).toString(), '1.2.4+11');
      expect(v.bump(BumpKind.minor).toString(), '1.3.0+11');
      expect(v.bump(BumpKind.major).toString(), '2.0.0+11');
    });
  });

  group('ordering decides whether a phone accepts an update', () {
    test('higher version, or same version with a higher build, is newer', () {
      expect(AppVersion.parse('1.1.0+4') > AppVersion.parse('1.0.2+3'), isTrue);
      expect(AppVersion.parse('1.0.2+4') > AppVersion.parse('1.0.2+3'), isTrue);
      expect(AppVersion.parse('1.0.2+3') < AppVersion.parse('1.0.2+4'), isTrue);
      expect(
        AppVersion.parse('1.0.2+3') == AppVersion.parse('1.0.2+3'),
        isTrue,
      );
    });

    test('numbers compare numerically, not as text', () {
      expect(
        AppVersion.parse('1.10.0+2') > AppVersion.parse('1.9.0+1'),
        isTrue,
      );
      expect(
        AppVersion.parse('1.0.0+100') > AppVersion.parse('1.0.0+99'),
        isTrue,
      );
    });

    test('versionCode must be a positive 32-bit-safe integer', () {
      expect(const AppVersion(1, 0, 0, 0).isValidAndroidVersionCode, isFalse);
      expect(const AppVersion(1, 0, 0, 1).isValidAndroidVersionCode, isTrue);
      expect(
        const AppVersion(1, 0, 0, 2100000001).isValidAndroidVersionCode,
        isFalse,
      );
    });
  });

  group('pubspec editing', () {
    const pubspec =
        'name: frontend\n'
        '# comment kept\n'
        'version: 1.0.2+3\n'
        'environment:\n'
        '  sdk: ^3.11.1\n';

    test('reads the version line', () {
      expect(AppVersion.fromPubspec(pubspec).toString(), '1.0.2+3');
      expect(AppVersion.fromPubspec('name: x\n'), isNull);
    });

    test('replaces only the version line', () {
      final out = AppVersion.replaceInPubspec(
        pubspec,
        AppVersion.parse('1.1.0+4'),
      );
      expect(out, pubspec.replaceFirst('1.0.2+3', '1.1.0+4'));
    });

    test('keeps CRLF line endings', () {
      final crlf = pubspec.replaceAll('\n', '\r\n');
      final out = AppVersion.replaceInPubspec(
        crlf,
        AppVersion.parse('1.1.0+4'),
      );
      expect(out, crlf.replaceFirst('1.0.2+3', '1.1.0+4'));
      expect(out.contains('version: 1.1.0+4\r\n'), isTrue);
    });

    test('throws when there is no version line', () {
      expect(
        () => AppVersion.replaceInPubspec(
          'name: x\n',
          AppVersion.parse('1.0.0+1'),
        ),
        throwsFormatException,
      );
    });
  });
}
