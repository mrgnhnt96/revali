import 'package:revali_core/context/request_context.dart';
import 'package:revali_core/request/request.dart';

abstract class FullRequest implements Request, RequestContext {
  const FullRequest();
}
