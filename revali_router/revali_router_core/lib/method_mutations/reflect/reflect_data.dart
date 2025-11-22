import 'package:equatable/equatable.dart';
import 'package:revali_router_core/method_mutations/reflect/reflector.dart';

class ReflectData extends Equatable {
  const ReflectData(
    this.type, {
    required this.metas,
  });

  final Type type;
  final void Function(Reflector) metas;

  @override
  List<Object?> get props => [type, metas];
}
