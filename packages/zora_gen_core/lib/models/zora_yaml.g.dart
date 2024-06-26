// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zora_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZoraYaml _$ZoraYamlFromJson(Map json) => ZoraYaml(
      constructs: (json['constructs'] as List<dynamic>?)
              ?.map((e) => ZoraConstructConfig.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ZoraYamlToJson(ZoraYaml instance) => <String, dynamic>{
      'constructs': instance.constructs.map((e) => e.toJson()).toList(),
    };
