import 'package:revali_router_core/body/body_data.dart';

abstract class MutableBody extends BodyData {
  void replace(Object? data);
  void operator []=(String key, Object? data);
}
