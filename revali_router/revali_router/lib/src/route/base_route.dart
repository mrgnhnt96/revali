import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/src/meta/combine_components_applier.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'base_route.g.dart';

// ignore: must_be_immutable
class BaseRoute extends Equatable implements RouteEntry, LifecycleComponents {
  BaseRoute(
    String path, {
    ResponseHandler? responseHandler,
    Future<dynamic> Function(Context)? handler,
    String? method,
    Iterable<BaseRoute>? routes,
    List<Middleware>? middlewares,
    List<Interceptor>? interceptors,
    List<Guard>? guards,
    // ignore: strict_raw_type
    List<ExceptionCatcher>? catchers,
    void Function(Meta)? meta,
    Redirect? redirect,
    List<CombineComponents> combine = const [],
    AllowOrigins? allowedOrigins,
    PreventHeaders? preventedHeaders,
    ExpectHeaders? expectedHeaders,
    bool ignorePathPattern = false,
  }) : this._(
          path,
          routes: routes,
          meta: meta,
          handler: handler,
          middlewares: middlewares ?? [],
          interceptors: interceptors ?? [],
          guards: guards ?? [],
          catchers: catchers ?? [],
          method: method?.toUpperCase(),
          redirect: redirect,
          combine: combine,
          allowedOrigins: allowedOrigins,
          preventedHeaders: preventedHeaders,
          ignorePathPattern: ignorePathPattern,
          responseHandler: responseHandler,
          expectedHeaders: expectedHeaders,
        );

  BaseRoute._(
    this.path, {
    required Iterable<BaseRoute>? routes,
    required this.middlewares,
    required this.interceptors,
    required this.handler,
    required this.method,
    required this.guards,
    required this.catchers,
    required this.redirect,
    required List<CombineComponents> combine,
    required this.allowedOrigins,
    required this.preventedHeaders,
    required bool ignorePathPattern,
    required ResponseHandler? responseHandler,
    required this.expectedHeaders,
    // dynamic is needed bc copyWith has a bug
    required dynamic meta,
  })  : _meta = meta as void Function(Meta)?,
        _responseHandler = responseHandler {
    final providedRoutes = routes?.toList();

    final method = this.method;

    if ((method == null) != (handler == null)) {
      throw ArgumentError('method and handler must be both provided or null');
    }

    if (method != null) {
      if (method.isEmpty) {
        throw ArgumentError('method cannot be empty');
      }
    }

    if (path.isEmpty &&
        handler != null &&
        providedRoutes != null &&
        providedRoutes.isNotEmpty) {
      throw ArgumentError('path cannot be empty if routes are provided');
    }

    if (path.startsWith('/') || path.endsWith('/')) {
      throw ArgumentError('path should not start nor end with /');
    }

    if (path.isNotEmpty) {
      final noSpecials = RegExp(r'[^a-z0-9\/\-_.:]', caseSensitive: false);
      if (noSpecials.hasMatch(path)) {
        throw ArgumentError(
          'path should not contain special characters, allowed: a-z, A-Z, 0-9, '
          ':, - and _ (pattern: ${noSpecials.pattern})',
        );
      }

      if (!ignorePathPattern) {
        final segmentPattern =
            RegExp(r'^:?[a-z0-9]+(?:[-_.][a-z0-9]+)*$', caseSensitive: false);
        final segments = path.split('/');
        if (!segments.every(segmentPattern.hasMatch)) {
          throw ArgumentError(
            'Invalid path format. Valid formats: /path/to/resource, path/:id (Segment pattern: ${segmentPattern.pattern})',
          );
        }
      }
    }

    CombineComponentsApplier(this, combine).apply();

    this.routes = providedRoutes?.map((e) => e.setParent(this)).toList();

    // assert no conflicting paths
    // user/:id conflicts with user/:name
    // (GET) user/:id doesn't conflict with user/:id (POST)
    if (this.routes case final routes?) {
      final nonDynamicPaths = <String, List<String>>{};
      for (final route in routes) {
        final fullPath = route.fullPath;
        final nonDynamicPath =
            fullPath.replaceAll(RegExp(r':\w+'), '<dynamic>');

        (nonDynamicPaths['${route.method}.$nonDynamicPath'] ??= [])
            .add(fullPath);
      }

      final conflicts = [
        for (final entry in nonDynamicPaths.entries)
          if (entry.value.length > 1) entry.value,
      ];

      if (conflicts.isNotEmpty) {
        throw ArgumentError(
          'Conflicting paths found:\n\t'
          '${conflicts.map((e) => e.join('\n\t')).join('\n\n\t')}',
        );
      }
    }
  }

  @override
  final String path;
  late final List<BaseRoute>? routes;
  @override
  final List<Middleware> middlewares;
  @override
  final List<Interceptor> interceptors;
  @override
  // ignore: strict_raw_type
  final List<ExceptionCatcher> catchers;
  @override
  final List<Guard> guards;

  @ignore
  @override
  BaseRoute? parent;

  @include
  bool get hasParent => parent != null;

  final Future<dynamic> Function(Context)? handler;
  @override
  final String? method;
  final void Function(Meta)? _meta;
  final Redirect? redirect;
  @override
  final AllowOrigins? allowedOrigins;
  @override
  final PreventHeaders? preventedHeaders;
  @override
  final ExpectHeaders? expectedHeaders;
  final ResponseHandler? _responseHandler;

  @override
  ResponseHandler? get responseHandler {
    if (_responseHandler case final handler?) {
      return handler;
    }

    var parent = this.parent;

    while (parent != null) {
      if (parent._responseHandler case final handler?) {
        return handler;
      }

      parent = parent.parent;
    }

    return null;
  }

  bool get canInvoke => handler != null && method != null;
  List<String> get segments => path.split('/');
  List<String> get fullSegments => fullPath.substring(1).split('/');
  bool get isDynamic => fullPath.contains(RegExp('[:*]'));
  bool get isStatic => !isDynamic;

  BaseRoute setParent(BaseRoute route) {
    parent = route;
    // ignore: avoid_returning_this
    return this;
  }

  @override
  Meta getMeta({Meta? handler, bool inherit = false}) {
    final meta = handler ?? Meta();

    void traverse(BaseRoute? route) {
      if (route == null) {
        return;
      }

      traverse(route.parent);
      route._meta?.call(meta);
    }

    if (inherit) {
      traverse(parent);
    } else {
      _meta?.call(meta);
    }

    return meta;
  }

  Set<String> get allowedMethods {
    final methods = <String>{'OPTIONS'};

    void add(String method) {
      methods.add(method);
      if (method == 'GET') {
        methods.add('HEAD');
      }
    }

    if (method case final value?) {
      add(value);
    }

    if (parent?.routes case final routes?) {
      for (final route in routes) {
        if (!route.matchesPath(this)) continue;

        if (route.method case final method?) {
          add(method);
        }
      }
    }

    return methods;
  }

  bool matchesPath(BaseRoute other) {
    if (path == other.path) {
      return true;
    }

    final segments = path.split('/');
    final otherSegments = other.path.split('/');

    if (segments.length != otherSegments.length) {
      return false;
    }

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final otherSegment = otherSegments[i];

      if (segment.startsWith(':') || otherSegment.startsWith(':')) {
        continue;
      }

      if (segment != otherSegment) {
        return false;
      }
    }

    return true;
  }

  @override
  String get fullPath {
    final buffer = StringBuffer();

    void write(BaseRoute? route) {
      if (route == null) {
        return;
      }

      write(route.parent);
      if (route.path.isNotEmpty) {
        buffer.write('/${route.path}');
      }
    }

    write(this);

    return buffer.toString();
  }

  Iterable<Middleware> get allMiddlewares sync* {
    Iterable<Middleware> traverse(BaseRoute? route) sync* {
      if (route == null) {
        return;
      }

      yield* traverse(route.parent);
      yield* route.middlewares;
    }

    yield* traverse(this);
  }

  Iterable<Interceptor> get allInterceptors sync* {
    Iterable<Interceptor> traverse(BaseRoute? route) sync* {
      if (route == null) {
        return;
      }

      yield* traverse(route.parent);
      yield* route.interceptors;
    }

    yield* traverse(this);
  }

  Iterable<Guard> get allGuards sync* {
    Iterable<Guard> traverse(BaseRoute? route) sync* {
      if (route == null) {
        return;
      }

      yield* traverse(route.parent);
      yield* route.guards;
    }

    yield* traverse(this);
  }

  // ignore: strict_raw_type
  Iterable<ExceptionCatcher> get allCatchers sync* {
    // ignore: strict_raw_type
    Iterable<ExceptionCatcher> traverse(BaseRoute? route) sync* {
      if (route == null) {
        return;
      }

      yield* route.catchers;
      yield* traverse(route.parent);
    }

    yield* traverse(this);
  }

  Iterable<String> get allAllowedOrigins sync* {
    Iterable<String> traverse(BaseRoute? route) sync* {
      if (route == null) {
        return;
      }

      if (route.allowedOrigins case final value?) {
        yield* value.origins;

        if (!value.inherit) {
          return;
        }
      }

      yield* traverse(route.parent);
      yield* route.allowedOrigins?.origins ?? [];
    }

    yield* traverse(this);
  }

  Iterable<String> get allPreventedHeaders sync* {
    Iterable<String> traverse(BaseRoute? route) sync* {
      if (route == null) {
        return;
      }

      if (route.preventedHeaders case final value?) {
        yield* value.headers;

        if (!value.inherit) {
          return;
        }
      }

      yield* traverse(route.parent);
    }

    yield* traverse(this);
  }

  Iterable<String> get allExpectedHeaders sync* {
    Iterable<String> traverse(BaseRoute? route) sync* {
      if (route == null) {
        return;
      }

      if (route.expectedHeaders case final value?) {
        yield* value.headers;
        return;
      }

      yield* traverse(route.parent);
    }

    yield* traverse(this);
  }

  @override
  List<Object?> get props => _$props;
}
