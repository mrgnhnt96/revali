// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revali_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

revaliYaml _$revaliYamlFromJson(Map json) => revaliYaml(
      constructs: (json['constructs'] as List<dynamic>?)
              ?.map((e) => revaliConstructConfig
                  .fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );

Map<String, dynamic> _$revaliYamlToJson(revaliYaml instance) =>
    <String, dynamic>{
      'constructs': instance.constructs.map((e) => e.toJson()).toList(),
    };
