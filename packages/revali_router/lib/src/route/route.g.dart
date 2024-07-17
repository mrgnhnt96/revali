// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// AutoequalGenerator
// **************************************************************************

extension _$RouteAutoequal on Route {
  List<Object?> get _$props => [
        path,
        routes,
        middlewares,
        interceptors,
        catchers,
        guards,
        handler,
        method,
        _meta,
        redirect,
        isWebSocket,
        ping,
        allowedOrigins,
        allowedHeaders,
      ];
}

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RouteCWProxy {
  Route path(String path);

  Route routes(Iterable<Route>? routes);

  Route middlewares(List<Middleware> middlewares);

  Route interceptors(List<Interceptor> interceptors);

  Route parent(Route? parent);

  Route handler(Future<void> Function(EndpointContext)? handler);

  Route method(String? method);

  Route guards(List<Guard> guards);

  Route catchers(List<ExceptionCatcher<Exception>> catchers);

  Route redirect(Redirect? redirect);

  Route isWebSocket(bool isWebSocket);

  Route combine(List<CombineMeta> combine);

  Route ping(Duration? ping);

  Route allowedOrigins(AllowOrigins? allowedOrigins);

  Route allowedHeaders(AllowHeaders? allowedHeaders);

  Route meta(dynamic meta);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Route(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Route(...).copyWith(id: 12, name: "My name")
  /// ````
  Route call({
    String? path,
    Iterable<Route>? routes,
    List<Middleware>? middlewares,
    List<Interceptor>? interceptors,
    Route? parent,
    Future<void> Function(EndpointContext)? handler,
    String? method,
    List<Guard>? guards,
    List<ExceptionCatcher<Exception>>? catchers,
    Redirect? redirect,
    bool? isWebSocket,
    List<CombineMeta>? combine,
    Duration? ping,
    AllowOrigins? allowedOrigins,
    AllowHeaders? allowedHeaders,
    dynamic meta,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRoute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRoute.copyWith.fieldName(...)`
class _$RouteCWProxyImpl implements _$RouteCWProxy {
  const _$RouteCWProxyImpl(this._value);

  final Route _value;

  @override
  Route path(String path) => this(path: path);

  @override
  Route routes(Iterable<Route>? routes) => this(routes: routes);

  @override
  Route middlewares(List<Middleware> middlewares) =>
      this(middlewares: middlewares);

  @override
  Route interceptors(List<Interceptor> interceptors) =>
      this(interceptors: interceptors);

  @override
  Route parent(Route? parent) => this(parent: parent);

  @override
  Route handler(Future<void> Function(EndpointContext)? handler) =>
      this(handler: handler);

  @override
  Route method(String? method) => this(method: method);

  @override
  Route guards(List<Guard> guards) => this(guards: guards);

  @override
  Route catchers(List<ExceptionCatcher<Exception>> catchers) =>
      this(catchers: catchers);

  @override
  Route redirect(Redirect? redirect) => this(redirect: redirect);

  @override
  Route isWebSocket(bool isWebSocket) => this(isWebSocket: isWebSocket);

  @override
  Route combine(List<CombineMeta> combine) => this(combine: combine);

  @override
  Route ping(Duration? ping) => this(ping: ping);

  @override
  Route allowedOrigins(AllowOrigins? allowedOrigins) =>
      this(allowedOrigins: allowedOrigins);

  @override
  Route allowedHeaders(AllowHeaders? allowedHeaders) =>
      this(allowedHeaders: allowedHeaders);

  @override
  Route meta(dynamic meta) => this(meta: meta);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Route(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Route(...).copyWith(id: 12, name: "My name")
  /// ````
  Route call({
    Object? path = const $CopyWithPlaceholder(),
    Object? routes = const $CopyWithPlaceholder(),
    Object? middlewares = const $CopyWithPlaceholder(),
    Object? interceptors = const $CopyWithPlaceholder(),
    Object? parent = const $CopyWithPlaceholder(),
    Object? handler = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
    Object? guards = const $CopyWithPlaceholder(),
    Object? catchers = const $CopyWithPlaceholder(),
    Object? redirect = const $CopyWithPlaceholder(),
    Object? isWebSocket = const $CopyWithPlaceholder(),
    Object? combine = const $CopyWithPlaceholder(),
    Object? ping = const $CopyWithPlaceholder(),
    Object? allowedOrigins = const $CopyWithPlaceholder(),
    Object? allowedHeaders = const $CopyWithPlaceholder(),
    Object? meta = const $CopyWithPlaceholder(),
  }) {
    return Route._(
      path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      routes: routes == const $CopyWithPlaceholder()
          ? _value.routes
          // ignore: cast_nullable_to_non_nullable
          : routes as Iterable<Route>?,
      middlewares:
          middlewares == const $CopyWithPlaceholder() || middlewares == null
              ? _value.middlewares
              // ignore: cast_nullable_to_non_nullable
              : middlewares as List<Middleware>,
      interceptors:
          interceptors == const $CopyWithPlaceholder() || interceptors == null
              ? _value.interceptors
              // ignore: cast_nullable_to_non_nullable
              : interceptors as List<Interceptor>,
      parent: parent == const $CopyWithPlaceholder()
          ? _value.parent
          // ignore: cast_nullable_to_non_nullable
          : parent as Route?,
      handler: handler == const $CopyWithPlaceholder()
          ? _value.handler
          // ignore: cast_nullable_to_non_nullable
          : handler as Future<void> Function(EndpointContext)?,
      method: method == const $CopyWithPlaceholder()
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as String?,
      guards: guards == const $CopyWithPlaceholder() || guards == null
          ? _value.guards
          // ignore: cast_nullable_to_non_nullable
          : guards as List<Guard>,
      catchers: catchers == const $CopyWithPlaceholder() || catchers == null
          ? _value.catchers
          // ignore: cast_nullable_to_non_nullable
          : catchers as List<ExceptionCatcher<Exception>>,
      redirect: redirect == const $CopyWithPlaceholder()
          ? _value.redirect
          // ignore: cast_nullable_to_non_nullable
          : redirect as Redirect?,
      isWebSocket:
          isWebSocket == const $CopyWithPlaceholder() || isWebSocket == null
              ? _value.isWebSocket
              // ignore: cast_nullable_to_non_nullable
              : isWebSocket as bool,
      combine: combine == const $CopyWithPlaceholder() || combine == null
          ? const []
          // ignore: cast_nullable_to_non_nullable
          : combine as List<CombineMeta>,
      ping: ping == const $CopyWithPlaceholder()
          ? _value.ping
          // ignore: cast_nullable_to_non_nullable
          : ping as Duration?,
      allowedOrigins: allowedOrigins == const $CopyWithPlaceholder()
          ? _value.allowedOrigins
          // ignore: cast_nullable_to_non_nullable
          : allowedOrigins as AllowOrigins?,
      allowedHeaders: allowedHeaders == const $CopyWithPlaceholder()
          ? _value.allowedHeaders
          // ignore: cast_nullable_to_non_nullable
          : allowedHeaders as AllowHeaders?,
      meta: meta == const $CopyWithPlaceholder() || meta == null
          ? _value._meta
          // ignore: cast_nullable_to_non_nullable
          : meta as dynamic,
    );
  }
}

extension $RouteCopyWith on Route {
  /// Returns a callable class that can be used as follows: `instanceOfRoute.copyWith(...)` or like so:`instanceOfRoute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RouteCWProxy get copyWith => _$RouteCWProxyImpl(this);
}
