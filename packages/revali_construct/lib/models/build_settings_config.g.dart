// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_settings_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildSettingsConfig _$BuildSettingsConfigFromJson(Map json) =>
    BuildSettingsConfig(
      targetOs: _targetOsFromJson(json['target_os']),
      targetArch: json['target_arch'] == null
          ? []
          : _targetArchFromJson(json['target_arch']),
      stripDebugInfo: json['strip_debug_info'] as bool? ?? false,
    );

Map<String, dynamic> _$BuildSettingsConfigToJson(
  BuildSettingsConfig instance,
) => <String, dynamic>{
  'target_os': _$TargetOsEnumMap[instance.targetOs],
  'target_arch': instance.targetArch.map((e) => _$ArchEnumMap[e]!).toList(),
  'strip_debug_info': instance.stripDebugInfo,
};

const _$TargetOsEnumMap = {
  TargetOs.linux: 'linux',
  TargetOs.macos: 'macos',
  TargetOs.windows: 'windows',
};

const _$ArchEnumMap = {
  Arch.arm: 'arm',
  Arch.arm64: 'arm64',
  Arch.ia32: 'ia32',
  Arch.riscv32: 'riscv32',
  Arch.riscv64: 'riscv64',
  Arch.x64: 'x64',
};
