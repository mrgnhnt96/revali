import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'construct_options.g.dart';

@JsonSerializable()
class ConstructOptions extends Equatable {
  const ConstructOptions();
  const ConstructOptions.empty();

  static ConstructOptions fromJson(Map json) =>
      _$ConstructOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$ConstructOptionsToJson(this);

  @override
  List<Object?> get props => [];
}
