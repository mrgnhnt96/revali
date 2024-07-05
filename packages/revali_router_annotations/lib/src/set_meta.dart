import 'package:revali_router/revali_router.dart';

final class SetMeta<T> {
  const SetMeta(this.value);

  final T value;

  void apply(MetaHandler data) {
    data.add<T>(value);
  }
}
