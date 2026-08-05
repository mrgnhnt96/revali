import 'package:revali_construct/enums/target_os.dart';
import 'package:revali_construct/models/revali_yaml.dart';
import 'package:test/test.dart';

void main() {
  group(RevaliYaml, () {
    test('fromJson with no build key leaves build null', () {
      final yaml = RevaliYaml.fromJson(const {'constructs': <dynamic>[]});

      expect(yaml.build, isNull);
    });

    test('fromJson parses a build section', () {
      final yaml = RevaliYaml.fromJson(const {
        'constructs': <dynamic>[],
        'build': {
          'target_os': 'linux',
          'target_arch': ['x64'],
        },
      });

      expect(yaml.build, isNotNull);
      expect(yaml.build!.targetOs, TargetOs.linux);
    });

    test('RevaliYaml.none has no build settings', () {
      const yaml = RevaliYaml.none();

      expect(yaml.build, isNull);
    });
  });
}
