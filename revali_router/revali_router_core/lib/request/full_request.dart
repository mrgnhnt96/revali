import 'package:revali_router_core/context/request_context.dart';
import 'package:revali_router_core/request/request.dart';

abstract class FullRequest implements Request, RequestContext {
  const FullRequest();
}
