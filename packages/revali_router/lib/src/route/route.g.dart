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
        catches,
        guards,
        handler,
        method,
        _meta,
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

  Route catches(List<ExceptionCatcher<dynamic>> catches);

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
    List<ExceptionCatcher<dynamic>>? catches,
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
  Route catches(List<ExceptionCatcher<dynamic>> catches) =>
      this(catches: catches);

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
    Object? catches = const $CopyWithPlaceholder(),
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
      catches: catches == const $CopyWithPlaceholder() || catches == null
          ? _value.catches
          // ignore: cast_nullable_to_non_nullable
          : catches as List<ExceptionCatcher<dynamic>>,
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
