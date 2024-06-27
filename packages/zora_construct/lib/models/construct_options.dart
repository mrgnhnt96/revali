import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'construct_options.g.dart';

@JsonSerializable()
class ConstructOptions extends Equatable {
  const ConstructOptions(this.values);
  const ConstructOptions.empty() : values = const {};

  static ConstructOptions fromJson(Map json) =>
      _$ConstructOptionsFromJson(json);

  final Map<String, dynamic> values;

  Map<String, dynamic> toJson() => _$ConstructOptionsToJson(this);

  @override
  List<Object?> get props => [];
}
