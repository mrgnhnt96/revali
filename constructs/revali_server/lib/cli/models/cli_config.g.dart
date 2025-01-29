// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cli_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CliConfig _$CliConfigFromJson(Map json) => CliConfig(
      createPaths: json['create_paths'] == null
          ? null
          : CreatePaths.fromJson(
              Map<String, dynamic>.from(json['create_paths'] as Map)),
    );

Map<String, dynamic> _$CliConfigToJson(CliConfig instance) => <String, dynamic>{
      'create_paths': instance.createPaths.toJson(),
    };
