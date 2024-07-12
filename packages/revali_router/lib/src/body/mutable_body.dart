import 'package:revali_router/src/body/read_only_body.dart';

abstract class MutableBody implements ReadOnlyBody {
  void replace(Object? data);
  void operator []=(String key, Object? data);
}
