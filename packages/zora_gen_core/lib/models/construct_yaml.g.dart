// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'construct_yaml.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConstructYaml _$ConstructYamlFromJson(Map json) => ConstructYaml(
      constructs: (json['constructs'] as List<dynamic>)
          .map((e) => ConstructConfig.fromJson(e as Map))
          .toList(),
      packagePath: json['package_path'] as String,
      packageUri: json['package_uri'] as String,
      packageName: json['package_name'] as String,
      packageRootUri: json['package_root_uri'] as String?,
    );

Map<String, dynamic> _$ConstructYamlToJson(ConstructYaml instance) =>
    <String, dynamic>{
      'constructs': instance.constructs.map((e) => e.toJson()).toList(),
      'package_path': instance.packagePath,
      'package_uri': instance.packageUri,
      'package_name': instance.packageName,
      'package_root_uri': instance.packageRootUri,
    };
