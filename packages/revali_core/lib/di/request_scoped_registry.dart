/// Exposes request-scoped registrations to the per-request container.
///
/// The application container is wrapped by `DIHandler` before it reaches the
/// router, so the per-request container cannot rely on being handed a
/// concrete `DIImpl`. Both implement this so the lookup works through the
/// wrapper.
abstract interface class RequestScopedRegistry {
  /// The factory registered for [T] with `registerRequestScoped`, or null if
  /// [T] is not request scoped.
  T Function()? requestScopedFactory<T extends Object>();
}
