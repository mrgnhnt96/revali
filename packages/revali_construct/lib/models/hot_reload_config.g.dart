// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_reload_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HotReloadConfig _$HotReloadConfigFromJson(Map json) => HotReloadConfig(
  exclude:
      (json['exclude'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$HotReloadConfigToJson(HotReloadConfig instance) =>
    <String, dynamic>{'exclude': instance.exclude};
