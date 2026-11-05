/// What a response tells the browser about one request's origin.
typedef CorsGrant = ({String allowOrigin, bool allowCredentials});

/// Decides, at runtime, what a request's origin is granted.
///
/// `@AllowOrigins` decides whether an origin is admitted at all and is fixed at
/// generate time. This decides what an admitted origin receives, so it can
/// depend on things only known at runtime, such as an allow-list read from the
/// environment.
///
/// Override `AppConfig.cors` to supply one:
///
/// ```dart
/// final class OriginsPolicy extends CorsPolicy {
///   const OriginsPolicy(this.trusted);
///
///   final Set<String> trusted;
///
///   @override
///   CorsGrant grant(String? origin) {
///     if (trusted.contains(origin)) {
///       return (allowOrigin: origin!, allowCredentials: true);
///     }
///
///     return (allowOrigin: '*', allowCredentials: false);
///   }
/// }
/// ```
class CorsPolicy {
  const CorsPolicy();

  /// The grant for a request from [origin], null when it sent no `Origin`
  /// header.
  ///
  /// Runs after the `@AllowOrigins` check, on every admitted request, and
  /// before any lifecycle component. That includes `OPTIONS` preflights, which
  /// never reach a component, so this is the only place an app can change what
  /// a preflight grants.
  ///
  /// By default the origin is reflected, or `*` without one, with credentials.
  ///
  /// Browsers refuse a credentialed response whose allowed origin is `*`, so
  /// return `allowCredentials: false` alongside it for an origin that should
  /// get a usable answer.
  CorsGrant grant(String? origin) {
    return (allowOrigin: origin ?? '*', allowCredentials: true);
  }
}
