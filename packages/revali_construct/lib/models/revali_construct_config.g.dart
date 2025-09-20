// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revali_construct_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevaliConstructConfig _$RevaliConstructConfigFromJson(Map json) =>
    RevaliConstructConfig(
      name: json['name'] as String,
      enabled: json['enabled'] as bool?,
      package: json['package'] as String?,
      options:
          (json['options'] as Map?)?.map((k, e) => MapEntry(k as String, e)) ??
          const {},
    );

Map<String, dynamic> _$RevaliConstructConfigToJson(
  RevaliConstructConfig instance,
) => <String, dynamic>{
  'name': instance.name,
  'package': instance.package,
  'enabled': instance.enabled,
  'options': instance.options,
};
