import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:revali_construct/models/construct_config.dart';

part 'construct_yaml.g.dart';

@JsonSerializable()
class ConstructYaml extends Equatable {
  const ConstructYaml({
    required this.constructs,
    required this.packagePath,
    required this.packageUri,
    required this.packageName,
    required this.packageRootUri,
  });

  // ignore: strict_raw_type
  static ConstructYaml fromJson(Map json) => _$ConstructYamlFromJson(json);

  Map<String, dynamic> toJson() => _$ConstructYamlToJson(this);

  final List<ConstructConfig> constructs;
  final String packagePath;
  final String packageUri;
  final String packageName;
  final String? packageRootUri;

  @override
  List<Object?> get props => [
        constructs,
        packagePath,
        packageUri,
        packageName,
        packageRootUri,
      ];
}
