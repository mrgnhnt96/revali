// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revali_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevaliYaml _$RevaliYamlFromJson(Map json) => RevaliYaml(
      constructs: (json['constructs'] as List<dynamic>?)
              ?.map((e) => RevaliConstructConfig.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );

Map<String, dynamic> _$RevaliYamlToJson(RevaliYaml instance) =>
    <String, dynamic>{
      'constructs': instance.constructs.map((e) => e.toJson()).toList(),
    };
