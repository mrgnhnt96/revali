import 'package:revali_core/components/request_listener.dart';
import 'package:revali_core/request/request.dart';
import 'package:revali_core/response/response.dart';

/// Sees a request as it begins, and is handed its response as a future.
///
/// For a summary of the finished request — status, duration, matched route —
/// implement `RequestObserver` instead, or as well.
abstract interface class Observer implements RequestListener {
  const Observer();

  Future<void> see(
    Request request,
    Future<Response> response,
  );
}
