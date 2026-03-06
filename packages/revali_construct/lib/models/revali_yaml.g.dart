// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revali_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevaliYaml _$RevaliYamlFromJson(Map json) => RevaliYaml(
  constructs:
      (json['constructs'] as List<dynamic>?)
          ?.map(
            (e) => RevaliConstructConfig.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList() ??
      [],
  hotReload: json['hot_reload'] == null
      ? null
      : HotReloadConfig.fromJson(
          Map<String, dynamic>.from(json['hot_reload'] as Map),
        ),
);

Map<String, dynamic> _$RevaliYamlToJson(RevaliYaml instance) =>
    <String, dynamic>{
      'constructs': instance.constructs.map((e) => e.toJson()).toList(),
      'hot_reload': instance.hotReload?.toJson(),
    };
