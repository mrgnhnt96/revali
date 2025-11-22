import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:revali_construct/models/construct_options.dart';

part 'construct_config.g.dart';

@JsonSerializable()
class ConstructConfig extends Equatable {
  const ConstructConfig({
    required this.name,
    required this.path,
    required this.method,
    this.options = const ConstructOptions.empty(),
    this.isServer = false,
    this.isBuild = false,
    this.optIn = false,
  }) : assert(
         !(isBuild & isServer),
         'Construct cannot be both a build and server construct',
       );

  // ignore: strict_raw_type
  static ConstructConfig fromJson(Map json) => _$ConstructConfigFromJson(json);

  final String name;
  final String path;
  final String method;
  final ConstructOptions options;
  final bool isServer;
  final bool isBuild;
  final bool optIn;

  Map<String, dynamic> toJson() => _$ConstructConfigToJson(this);

  @override
  List<Object?> get props => [name, path, method, options, isServer, isBuild];
}
