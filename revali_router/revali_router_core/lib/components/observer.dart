import 'package:revali_router_core/request/request.dart';
import 'package:revali_router_core/response/response.dart';

abstract interface class Observer {
  const Observer();

  Future<void> see(
    Request request,
    Future<Response> response,
  );
}
