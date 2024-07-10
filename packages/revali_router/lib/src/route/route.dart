import 'package:autoequal/autoequal.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_router/src/endpoint/endpoint_context.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher.dart';
import 'package:revali_router/src/guard/guard.dart';
import 'package:revali_router/src/interceptor/interceptor.dart';
import 'package:revali_router/src/meta/combine_meta.dart';
import 'package:revali_router/src/meta/combine_meta_applier.dart';
import 'package:revali_router/src/meta/meta_handler.dart';
import 'package:revali_router/src/middleware/middleware.dart';
import 'package:revali_router/src/redirect/redirect.dart';
import 'package:revali_router/src/route/route_entry.dart';
import 'package:revali_router/src/route/route_modifiers.dart';

part 'route.g.dart';

@CopyWith(constructor: '_')
class Route extends Equatable implements RouteEntry, RouteModifiers {
  Route(
    this.path, {
    this.handler,
    String? method,
    List<Route>? routes,
    this.middlewares = const [],
    this.interceptors = const [],
    this.guards = const [],
    this.catchers = const [],
    void Function(MetaHandler)? meta,
    this.redirect,
    List<CombineMeta> combine = const [],
  })  : parent = null,
        _meta = meta,
        method = method?.toUpperCase() {
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
      final noSpecials = RegExp(r'[^a-z\/\-_.:]', caseSensitive: false);
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

  Route._(
    this.path, {
    required this.routes,
    required this.middlewares,
    required this.interceptors,
    required this.parent,
    required this.handler,
    required this.method,
    required this.guards,
    required this.catchers,
    required this.redirect,
    // dynamic is needed bc copyWith has a bug
    required meta,
  }) : _meta = meta as void Function(MetaHandler)?;

  static void validateRoutes(List<RouteModifiers> routes) {}

  final String path;
  late final Iterable<Route>? routes;
  final List<Middleware> middlewares;
  final List<Interceptor> interceptors;
  final List<ExceptionCatcher> catchers;
  final List<Guard> guards;
  @ignore
  final Route? parent;
  final Future<void> Function(EndpointContext)? handler;
  final String? method;
  final void Function(MetaHandler)? _meta;
  final Redirect? redirect;

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

  List<String> get segments => path.split('/');

  @override
  List<Object?> get props => _$props;
}
