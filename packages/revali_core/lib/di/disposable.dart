import 'dart:async';

/// Released automatically when the scope that created it ends.
///
/// A request-scoped dependency registered with `DI.registerRequestScoped` is
/// disposed once its request finishes, whether it succeeded or threw. Use it
/// for anything holding a resource for the length of one request — a database
/// transaction, a batched writer, an open file.
///
/// Disposal happens in reverse creation order, so a dependency can rely on
/// whatever it was built from still being alive. Errors thrown here are
/// logged and do not fail the response, which has already been sent.
abstract interface class Disposable {
  FutureOr<void> dispose();
}
