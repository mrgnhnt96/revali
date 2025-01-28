// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_paths.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePaths _$CreatePathsFromJson(Map json) => CreatePaths(
      controller: CreatePaths._multiString(json['controller']),
      app: CreatePaths._multiString(json['app']),
      pipe: CreatePaths._multiString(json['pipe']),
      lifecycleComponent: CreatePaths._multiString(json['lifecycle_component']),
    );

Map<String, dynamic> _$CreatePathsToJson(CreatePaths instance) =>
    <String, dynamic>{
      'controller': instance.controller,
      'app': instance.app,
      'pipe': instance.pipe,
      'lifecycle_component': instance.lifecycleComponent,
    };
