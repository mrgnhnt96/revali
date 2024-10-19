import 'package:equatable/equatable.dart';
import 'package:revali_router_core/reflect/write_only_reflector.dart';

part 'reflect.g.dart';

class Reflect extends Equatable {
  const Reflect(
    this.type, {
    required this.metas,
  });

  final Type type;
  final void Function(WriteOnlyReflector) metas;

  @override
  List<Object?> get props => _$props;
}
