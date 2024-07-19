import 'package:revali_router_core/request/read_only_request_context.dart';
import 'package:revali_router_core/response/read_only_response_context.dart';

abstract class Observer {
  const Observer();

  void see(
    ReadOnlyRequestContext request,
    Future<ReadOnlyResponseContext> response,
  );
}
