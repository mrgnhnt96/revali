import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:revali_construct/enums/arch.dart';
import 'package:revali_construct/enums/target_os.dart';
import 'package:revali_construct/models/revali_build_context.dart';

part 'build_settings_config.g.dart';

/// The `build:` section of `revali.yaml`. Its mere presence signals that
/// `revali build` should compile a native executable via
/// `dart compile exe --target-os --target-arch`, made available to
/// build-type constructs through [RevaliBuildContext.compiledExecutables].
@JsonSerializable()
class BuildSettingsConfig extends Equatable {
  const BuildSettingsConfig({
    this.targetOs,
    List<Arch>? targetArch,
    this.stripDebugInfo = false,
  }) : targetArch = targetArch ?? const [];

  factory BuildSettingsConfig.fromJson(Map<String, dynamic> json) =>
      _$BuildSettingsConfigFromJson(json);

  @JsonKey(name: 'target_os', fromJson: _targetOsFromJson)
  final TargetOs? targetOs;

  @JsonKey(name: 'target_arch', defaultValue: [], fromJson: _targetArchFromJson)
  final List<Arch> targetArch;

  @JsonKey(name: 'strip_debug_info', defaultValue: false)
  final bool stripDebugInfo;

  /// [targetOs], defaulting to the host OS when omitted.
  TargetOs get resolvedTargetOs => targetOs ?? TargetOs.current();

  /// [targetArch], defaulting to the host architecture when empty.
  List<Arch> get resolvedTargetArch =>
      targetArch.isEmpty ? [Arch.current()] : targetArch;

  Map<String, dynamic> toJson() => _$BuildSettingsConfigToJson(this);

  @override
  List<Object?> get props => [targetOs, targetArch, stripDebugInfo];
}

TargetOs? _targetOsFromJson(Object? json) => TargetOs.fromName(json as String?);

List<Arch> _targetArchFromJson(Object? json) => switch (json) {
  final List<dynamic> list => [
    for (final e in list)
      if (Arch.fromName('$e') case final arch?) arch,
  ],
  _ => const [],
};
