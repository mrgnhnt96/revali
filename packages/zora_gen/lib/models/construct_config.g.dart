// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'construct_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConstructConfig _$ConstructConfigFromJson(Map json) => ConstructConfig(
      name: json['name'] as String,
      path: json['path'] as String,
      method: json['method'] as String,
      options: json['options'] == null
          ? const ConstructOptions.empty()
          : ConstructOptions.fromJson(json['options'] as Map),
    );

Map<String, dynamic> _$ConstructConfigToJson(ConstructConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'method': instance.method,
      'options': instance.options.toJson(),
    };
