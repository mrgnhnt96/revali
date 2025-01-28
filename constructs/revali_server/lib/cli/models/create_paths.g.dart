// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_paths.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePaths _$CreatePathsFromJson(Map json) => CreatePaths(
      controller: json['controller'] as String?,
      app: json['app'] as String?,
      pipe: CreatePaths._multiString(json['pipe']),
    );

Map<String, dynamic> _$CreatePathsToJson(CreatePaths instance) =>
    <String, dynamic>{
      'controller': instance.controller,
      'app': instance.app,
      'pipe': instance.pipe,
    };
