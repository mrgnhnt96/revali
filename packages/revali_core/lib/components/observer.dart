import 'dart:async';

import 'package:revali_core/components/request_summary.dart';
import 'package:revali_core/request/request.dart';
import 'package:revali_core/response/response.dart';

/// One request, as an observer sees it.
///
/// Carries both ends: what is known at the start, and futures for what is
/// only known once the request finishes. An observer takes whichever it
/// needs — there is no second interface to implement for the later half.
class ObservedRequest {
  const ObservedRequest({
    required this.request,
    required this.response,
    required this.summary,
  });

  /// The incoming request. Available immediately.
  final Request request;

  /// The response, once the pipeline has produced it.
  final Future<Response> response;

  /// How the request turned out: status, duration, and the **registered**
  /// path of the route that matched.
  ///
  /// Label metrics with [RequestSummary.routePath] (`/api/users/:id`) rather
  /// than the concrete path (`/api/users/42`) — that is the difference
  /// between one time series and one per id.
  final Future<RequestSummary> summary;
}

/// Watches requests.
///
/// [see] is called as the request begins and is **not** awaited, so an
/// observer is free to await [ObservedRequest.summary] and report once the
/// request has finished:
///
/// ```dart
/// class Metrics implements Observer {
///   const Metrics();
///
///   @override
///   Future<void> see(ObservedRequest observed) async {
///     final summary = await observed.summary;
///
///     requests.labels(summary.routePath ?? 'unmatched').inc();
///     latency.observe(summary.duration.inMilliseconds);
///   }
/// }
/// ```
///
/// Or report immediately, and ignore the futures entirely:
///
/// ```dart
/// @override
/// void see(ObservedRequest observed) {
///   log('${observed.request.method} ${observed.request.uri}');
/// }
/// ```
///
/// Errors are caught and logged rather than allowed to reach the response —
/// a broken exporter must not take the request with it.
abstract interface class Observer {
  const Observer();

  FutureOr<void> see(ObservedRequest observed);
}
