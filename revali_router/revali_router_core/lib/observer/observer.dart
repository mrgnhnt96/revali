import 'package:revali_router_core/request/read_only_request.dart';
import 'package:revali_router_core/response/read_only_response.dart';

abstract interface class Observer {
  const Observer();

  Future<void> see(
    ReadOnlyRequest request,
    Future<ReadOnlyResponse> response,
  );
}
