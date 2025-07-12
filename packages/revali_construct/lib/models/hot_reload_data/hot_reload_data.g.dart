// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_reload_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HotReloadData _$HotReloadDataFromJson(Map json) => HotReloadData(
      type: $enumDecode(_$HotReloadTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$HotReloadDataToJson(HotReloadData instance) =>
    <String, dynamic>{
      'type': _$HotReloadTypeEnumMap[instance.type]!,
    };

const _$HotReloadTypeEnumMap = {
  HotReloadType.filesChanged: 'filesChanged',
  HotReloadType.revaliStarted: 'revaliStarted',
  HotReloadType.hotReloadEnabled: 'hotReloadEnabled',
};
