import 'package:revali_router_core/revali_router_core.dart';

abstract class FullRequest
    implements MutableRequest, RequestContext, ReadOnlyRequest {
  const FullRequest();
}
