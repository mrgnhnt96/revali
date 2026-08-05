import 'package:revali_construct/enums/arch.dart';
import 'package:revali_construct/enums/target_os.dart';
import 'package:revali_construct/models/build_settings_config.dart';
import 'package:test/test.dart';

void main() {
  group(BuildSettingsConfig, () {
    test('fromJson with an empty map defaults every field', () {
      final settings = BuildSettingsConfig.fromJson(const {});

      expect(settings.targetOs, isNull);
      expect(settings.targetArch, isEmpty);
      expect(settings.stripDebugInfo, isFalse);
    });

    test('fromJson parses target_os, target_arch, and strip_debug_info', () {
      final settings = BuildSettingsConfig.fromJson(const {
        'target_os': 'linux',
        'target_arch': ['x64', 'arm64'],
        'strip_debug_info': true,
      });

      expect(settings.targetOs, TargetOs.linux);
      expect(settings.targetArch, [Arch.x64, Arch.arm64]);
      expect(settings.stripDebugInfo, isTrue);
    });

    test('fromJson ignores unknown target_arch entries', () {
      final settings = BuildSettingsConfig.fromJson(const {
        'target_arch': ['x64', 'not-a-real-arch'],
      });

      expect(settings.targetArch, [Arch.x64]);
    });

    test('fromJson treats an unknown target_os as absent', () {
      final settings = BuildSettingsConfig.fromJson(const {
        'target_os': 'not-a-real-os',
      });

      expect(settings.targetOs, isNull);
    });

    test('resolvedTargetOs defaults to the host OS when unset', () {
      const settings = BuildSettingsConfig();

      expect(settings.resolvedTargetOs, TargetOs.current());
    });

    test('resolvedTargetOs keeps an explicit target_os', () {
      const settings = BuildSettingsConfig(targetOs: TargetOs.linux);

      expect(settings.resolvedTargetOs, TargetOs.linux);
    });

    test('resolvedTargetArch defaults to the host arch when empty', () {
      const settings = BuildSettingsConfig();

      expect(settings.resolvedTargetArch, [Arch.current()]);
    });

    test('resolvedTargetArch keeps explicit values', () {
      const settings = BuildSettingsConfig(targetArch: [Arch.x64, Arch.arm64]);

      expect(settings.resolvedTargetArch, [Arch.x64, Arch.arm64]);
    });

    test('toJson round-trips through fromJson', () {
      const settings = BuildSettingsConfig(
        targetOs: TargetOs.linux,
        targetArch: [Arch.x64, Arch.arm64],
        stripDebugInfo: true,
      );

      final roundTripped = BuildSettingsConfig.fromJson(settings.toJson());

      expect(roundTripped, settings);
    });
  });
}
