import 'package:autoequal/autoequal.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_router/src/meta/combine_meta_applier.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'route.g.dart';

typedef Handler = Future<void> Function(EndpointContext);

@CopyWith(constructor: '_')
class Route extends Equatable implements RouteEntry, RouteModifiers {
  Route(
    String path, {
    Handler? handler,
    String? method,
    Iterable<Route>? routes,
    List<Middleware>? middlewares,
    List<Interceptor>? interceptors,
    List<Guard>? guards,
    List<ExceptionCatcher>? catchers,
    void Function(MetaHandler)? meta,
    Redirect? redirect,
    List<CombineMeta> combine = const [],
    Set<String>? allowedOrigins,
    Set<String>? allowedHeaders,
  }) : this._(
          path,
          routes: routes,
          meta: meta,
          handler: handler,
          parent: null,
          isWebSocket: false,
          ping: null,
          middlewares: middlewares ?? [],
          interceptors: interceptors ?? [],
          guards: guards ?? [],
          catchers: catchers ?? [],
          method: method?.toUpperCase(),
          redirect: redirect,
          combine: combine,
          allowedOrigins: allowedOrigins ?? {},
          allowedHeaders: allowedHeaders ?? {},
        );

  Route.webSocket(
    String path, {
    required Handler handler,
    Iterable<Route>? routes,
    List<Middleware>? middlewares,
    List<Interceptor>? interceptors,
    List<Guard>? guards,
    List<ExceptionCatcher>? catchers,
    void Function(MetaHandler)? meta,
    Redirect? redirect,
    List<CombineMeta> combine = const [],
    Duration? ping,
    Set<String>? allowedOrigins,
    Set<String>? allowedHeaders,
  }) : this._(
          path,
          parent: null,
          isWebSocket: true,
          handler: handler,
          method: 'GET',
          routes: routes,
          middlewares: middlewares ?? [],
          interceptors: interceptors ?? [],
          guards: guards ?? [],
          catchers: catchers ?? [],
          meta: meta,
          redirect: redirect,
          combine: combine,
          ping: ping,
          allowedOrigins: allowedOrigins ?? {},
          allowedHeaders: allowedHeaders ?? {},
        );

  Route._(
    this.path, {
    required Iterable<Route>? routes,
    required this.middlewares,
    required this.interceptors,
    required this.parent,
    required this.handler,
    required this.method,
    required this.guards,
    required this.catchers,
    required this.redirect,
    required this.isWebSocket,
    required List<CombineMeta> combine,
    required this.ping,
    required this.allowedOrigins,
    required this.allowedHeaders,
    // dynamic is needed bc copyWith has a bug
    required meta,
  }) : _meta = meta as void Function(MetaHandler)? {
    final method = this.method;

    if ((method == null) != (handler == null)) {
      throw ArgumentError('method and handler must be both provided or null');
    }

    if (method != null) {
      if (method.isEmpty) {
        throw ArgumentError('method cannot be empty');
      }
    }

    if (path.isEmpty && routes?.isNotEmpty == true) {
      throw ArgumentError('path cannot be empty if routes are provided');
    }

    if (path.startsWith('/') || path.endsWith('/')) {
      throw ArgumentError('path should not start nor end with /');
    }

    if (path.isNotEmpty) {
      final noSpecials = RegExp(r'[^a-z0-9\/\-_.:]', caseSensitive: false);
      if (noSpecials.hasMatch(path)) {
        throw ArgumentError(
          'path should not contain special characters, allowed: a-z, A-Z, 0-9, :, - and _ (pattern: ${noSpecials.pattern})',
        );
      }

      final segmentPattern =
          RegExp(r'^:?[a-z0-9]+(?:[-_.][a-z0-9]+)*$', caseSensitive: false);
      final segments = path.split('/');
      if (!segments.every((p) => segmentPattern.hasMatch(p))) {
        throw ArgumentError(
          'Invalid path format. Valid formats: /path/to/resource, path/:id (Segment pattern: ${segmentPattern.pattern})',
        );
      }
    }

    CombineMetaApplier(this, combine).apply();

    this.routes = routes?.map((e) => e.copyWith.parent(this));

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
          if (entry.value.length > 1) entry.value
      ];

      if (conflicts.isNotEmpty) {
        throw ArgumentError(
          'Conflicting paths found:\n\t${conflicts.map((e) => e.join('\n\t')).join('\n\n\t')}',
        );
      }
    }
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

  static void validateRoutes(List<RouteModifiers> routes) {}

  final String path;
  late final Iterable<Route>? routes;
  final List<Middleware> middlewares;
  final List<Interceptor> interceptors;
  final List<ExceptionCatcher> catchers;
  final List<Guard> guards;
  @ignore
  final Route? parent;
  final Handler? handler;
  final String? method;
  final void Function(MetaHandler)? _meta;
  final Redirect? redirect;
  final bool isWebSocket;
  final Duration? ping;
  final Set<String> allowedOrigins;
  final Set<String> allowedHeaders;

  bool get isDynamic => segments.any((s) => s.startsWith(':'));
  bool get isStatic => !isDynamic;

  MetaHandler getMeta({MetaHandler? handler, bool inherit = false}) {
    final meta = handler ?? MetaHandler();

    void traverse(Route? route) {
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

  bool get canInvoke => handler != null && method != null;

  String get fullPath {
    final buffer = StringBuffer();

    void write(Route? route) {
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
    Iterable<Middleware> traverse(Route? route) sync* {
      if (route == null) {
        return;
      }

      yield* traverse(route.parent);
      yield* route.middlewares;
    }

    yield* traverse(this);
  }

  Iterable<Interceptor> get allInterceptors sync* {
    Iterable<Interceptor> traverse(Route? route) sync* {
      if (route == null) {
        return;
      }

      yield* traverse(route.parent);
      yield* route.interceptors;
    }

    yield* traverse(this);
  }

  Iterable<Guard> get allGuards sync* {
    Iterable<Guard> traverse(Route? route) sync* {
      if (route == null) {
        return;
      }

      yield* traverse(route.parent);
      yield* route.guards;
    }

    yield* traverse(this);
  }

  Iterable<ExceptionCatcher> get allCatchers sync* {
    Iterable<ExceptionCatcher> traverse(Route? route) sync* {
      if (route == null) {
        return;
      }

      yield* route.catchers;
      yield* traverse(route.parent);
    }

    yield* traverse(this);
  }

  Iterable<String> get allAllowedOrigins sync* {
    Iterable<String> traverse(Route? route) sync* {
      if (route == null) {
        return;
      }

      yield* traverse(route.parent);
      yield* route.allowedOrigins;
    }

    yield* traverse(this);
  }

  Iterable<String> get allAllowedHeaders sync* {
    Iterable<String> traverse(Route? route) sync* {
      if (route == null) {
        return;
      }

      yield* traverse(route.parent);
      yield* route.allowedHeaders;
    }

    yield* traverse(this);
  }

  List<String> get segments => path.split('/');

  bool matchesPath(Route other) {
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
  List<Object?> get props => _$props;
}
