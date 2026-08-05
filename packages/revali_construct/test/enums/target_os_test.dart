import 'package:revali_construct/enums/target_os.dart';
import 'package:test/test.dart';

void main() {
  group(TargetOs, () {
    test('fromName parses valid names and returns null otherwise', () {
      expect(TargetOs.fromName('linux'), TargetOs.linux);
      expect(TargetOs.fromName('macos'), TargetOs.macos);
      expect(TargetOs.fromName('windows'), TargetOs.windows);
      expect(TargetOs.fromName('bogus'), isNull);
      expect(TargetOs.fromName(null), isNull);
    });

    group('canCompile', () {
      test('linux is compilable from any host', () {
        for (final host in TargetOs.values) {
          expect(host.canCompile(TargetOs.linux), isTrue, reason: '$host');
        }
      });

      test('macos requires a macos host', () {
        expect(TargetOs.macos.canCompile(TargetOs.macos), isTrue);
        expect(TargetOs.linux.canCompile(TargetOs.macos), isFalse);
        expect(TargetOs.windows.canCompile(TargetOs.macos), isFalse);
      });

      test('windows requires a windows host', () {
        expect(TargetOs.windows.canCompile(TargetOs.windows), isTrue);
        expect(TargetOs.linux.canCompile(TargetOs.windows), isFalse);
        expect(TargetOs.macos.canCompile(TargetOs.windows), isFalse);
      });
    });
  });
}
