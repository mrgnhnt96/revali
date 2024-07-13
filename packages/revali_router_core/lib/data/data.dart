import 'package:revali_router_core/data/data_handler.dart';

final class Data<T> {
  const Data(this.value);

  final T value;

  void apply(DataHandler data) {
    data.add<T>(value);
  }
}
