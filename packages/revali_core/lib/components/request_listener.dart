/// Common supertype for everything an app registers as an observer.
///
/// Exists so that watching requests is not one fixed shape. `Observer` sees a
/// request as it begins; `RequestObserver` sees a summary once it finishes.
/// They answer different questions, and neither should have to implement the
/// other's method to be registered.
///
/// Everything the app declares — `@Observers([...])` or an observer
/// annotation — is collected as a [RequestListener], and the router dispatches
/// to whichever interfaces each one actually implements.
abstract interface class RequestListener {
  const RequestListener();
}
