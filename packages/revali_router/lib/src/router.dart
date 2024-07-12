import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/endpoint/endpoint_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_action.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_meta_impl.dart';
import 'package:revali_router/src/guard/guard_action.dart';
import 'package:revali_router/src/guard/guard_context_impl.dart';
import 'package:revali_router/src/guard/guard_meta.dart';
import 'package:revali_router/src/interceptor/interceptor_context_impl.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';
import 'package:revali_router/src/meta/meta_handler.dart';
import 'package:revali_router/src/middleware/middleware_action.dart';
import 'package:revali_router/src/middleware/middleware_context_impl.dart';
import 'package:revali_router/src/reflect/reflect.dart';
import 'package:revali_router/src/reflect/reflect_handler.dart';
import 'package:revali_router/src/request/mutable_request_context_impl.dart';
import 'package:revali_router/src/request/parts/response.dart';
import 'package:revali_router/src/request/parts/web_socket_response.dart';
import 'package:revali_router/src/request/request_context.dart';
import 'package:revali_router/src/response/mutable_response_context_impl.dart';
import 'package:revali_router/src/route/route.dart';
import 'package:revali_router/src/route/route_match.dart';
import 'package:revali_router/src/route/route_modifiers.dart';

part 'router.g.dart';

class Router extends Equatable {
  const Router._(
    this.context, {
    required this.routes,
    required RouteModifiers? globalModifiers,
    required Set<Reflect> reflects,
  })  : _reflects = reflects,
        _globalModifiers = globalModifiers;

  const Router(
    RequestContext context, {
    required List<Route> routes,
    RouteModifiers? globalModifiers,
    Set<Reflect> reflects = const {},
  }) : this._(
          context,
          routes: routes,
          globalModifiers: globalModifiers,
          reflects: reflects,
        );

  Router.request(
    HttpRequest request, {
    required List<Route> routes,
    RouteModifiers? globalModifiers,
    Set<Reflect> reflects = const {},
  }) : this._(
          RequestContext.from(request),
          routes: routes,
          globalModifiers: globalModifiers,
          reflects: reflects,
        );

  final RequestContext context;
  final List<Route> routes;
  final Set<Reflect> _reflects;
  final RouteModifiers? _globalModifiers;

  Future<Response> handle() async {
    final request = MutableRequestContextImpl.from(this.context);
    final segments = request.segments;

    final match = find(
      segments: segments,
      routes: routes,
      method: request.method,
    );

    if (match == null) {
      return Response.notFound('Failed to find ${segments.join('/')}');
    }

    final RouteMatch(:route, :pathParameters) = match;

    if (route.redirect case final redirect?) {
      return Response(
        redirect.code,
        headers: {
          'Location': redirect.path,
        },
      );
    }

    request.setPathParameters(pathParameters);

    final response = MutableResponseContextImpl();

    if (route.isPublicFile) {
      return await _serverPublicFile(route, response) ?? response.get();
    }

    final globalModifiers = _globalModifiers ?? RouteModifiers();
    final directMeta = route.getMeta();
    final inheritedMeta = route.getMeta(inherit: true);
    globalModifiers.getMeta(handler: inheritedMeta);
    final dataHandler = DataHandler();
    final reflectHandler = ReflectHandler(_reflects);

    try {
      final result = await execute(
        route: route,
        globalModifiers: globalModifiers,
        request: request,
        response: response,
        dataHandler: dataHandler,
        directMeta: directMeta,
        inheritedMeta: inheritedMeta,
        reflectHandler: reflectHandler,
      );

      return result;
    } catch (e) {
      if (e is! Exception) {
        return Response.internalServerError();
      }

      final catchers = [
        ...route.allCatchers,
        ...globalModifiers.catchers,
      ];

      for (final catcher in catchers) {
        if (!catcher.canCatch(e)) {
          continue;
        }

        final result = await catcher.catchException(
          e,
          ExceptionCatcherContextImpl(
            data: dataHandler,
            meta: ExceptionCatcherMetaImpl(
              direct: directMeta,
              inherited: inheritedMeta,
              route: route,
            ),
            request: request,
            response: response,
          ),
          const ExceptionCatcherAction(),
        );

        if (result.isHandled) {
          final (statusCode, headers, body) =
              result.asHandled.getResponseOverrides();

          return response.overrideWith(
            statusCode: statusCode,
            defaultStatusCode: 500,
            headers: headers,
            body: body,
          );
        }
      }

      return Response.internalServerError();
    }
  }

  Future<Response> execute({
    required Route route,
    required RouteModifiers globalModifiers,
    required MutableRequestContextImpl request,
    required MutableResponseContextImpl response,
    required DataHandler dataHandler,
    required MetaHandler directMeta,
    required MetaHandler inheritedMeta,
    required ReflectHandler reflectHandler,
  }) async {
    final handler = route.handler;
    if (handler == null) {
      return Response.notFound(null);
    }

    final middlewares = [
      ...globalModifiers.middlewares,
      ...route.allMiddlewares,
    ];
    for (final middleware in middlewares) {
      final result = await middleware.use(
        MiddlewareContextImpl(
          request: request,
          response: response,
          data: dataHandler,
        ),
        const MiddlewareAction(),
      );

      if (result.isStop) {
        final (statusCode, headers, body) =
            result.asStop.getResponseOverrides();

        return response.overrideWith(
          statusCode: statusCode,
          defaultStatusCode: 400,
          headers: headers,
          body: jsonEncode(body),
        );
      }
    }

    final guards = [
      ...globalModifiers.guards,
      ...route.allGuards,
    ];
    for (final guard in guards) {
      final result = await guard.canActivate(
        GuardContextImpl(
          meta: GuardMeta(
            direct: directMeta,
            inherited: inheritedMeta,
            route: route,
          ),
          response: response,
          request: request,
          data: dataHandler,
        ),
        const GuardAction(),
      );

      if (result.isNo) {
        final (statusCode, headers, body) = result.asNo.getResponseOverrides();
        return response.overrideWith(
          statusCode: statusCode,
          defaultStatusCode: 403,
          headers: headers,
          body: body,
        );
      }
    }

    Future<void> run() async {
      final interceptors = [
        ...globalModifiers.interceptors,
        ...route.allInterceptors,
      ];
      for (final interceptor in interceptors) {
        await interceptor.pre(
          InterceptorContextImpl(
            meta: InterceptorMeta(
              direct: directMeta,
              inherited: inheritedMeta,
            ),
            reflect: reflectHandler,
            request: request,
            response: response,
            data: dataHandler,
          ),
        );
      }

      await handler.call(
        EndpointContextImpl(
          meta: directMeta,
          reflect: reflectHandler,
          request: request,
          data: dataHandler,
          response: response,
        ),
      );

      for (final interceptor in interceptors) {
        await interceptor.post(
          InterceptorContextImpl(
            meta: InterceptorMeta(
              direct: directMeta,
              inherited: inheritedMeta,
            ),
            reflect: reflectHandler,
            request: request,
            response: response,
            data: dataHandler,
          ),
        );
      }
    }

    if (route.isWebSocket) {
      WebSocket webSocket;
      try {
        webSocket = await context.upgradeToWebSocket();
      } catch (e) {
        return Response.internalServerError();
      }

      final sub = webSocket.listen((event) async {
        response.clearBody();
        await request.overrideBody(event);

        await run();

        final body = response.body;
        if (body == null || body.isEmpty) {
          return;
        }

        webSocket.add(utf8.encode(jsonEncode(body)));
      });

      await sub.asFuture();

      return WebSocketStopResponse();
    }

    await run();
    return response.get();
  }

  RouteMatch? find({
    required Iterable<String> segments,
    required Iterable<Route>? routes,
    required String method,
  }) {
    RouteMatch? _find({
      required Iterable<String> pathSegments,
      required Iterable<Route>? routes,
      required Route? parent,
      required String method,
      required Map<String, String> pathParameters,
    }) {
      if (routes == null || routes.isEmpty) {
        if (parent == null) {
          return null;
        }

        final parts = pathSegments.take(parent.segments.length);
        final _remainingPathSegments = pathSegments.skip(parts.length).toList();

        if (_remainingPathSegments.isEmpty &&
                (parent.canInvoke && parent.method == method) ||
            parent.isPublicFile) {
          return RouteMatch(
            route: parent,
            pathParameters: pathParameters,
          );
        }

        return null;
      }

      final sorted = routes.toList()
        // dynamic goes last
        ..sort((a, b) => a.isDynamic ? 1 : 0);

      for (final route in sorted) {
        if (pathSegments.length < route.segments.length) {
          continue;
        }

        final _pathSegments = pathSegments.take(route.segments.length);

        if (route.isDynamic) {
          final _segments = [
            for (final segment in route.segments.take(_pathSegments.length))
              if (segment.startsWith(':')) r'(.+)' else segment
          ];

          final pattern = RegExp('^${_segments.join(r'\/')}\$');

          if (pattern.hasMatch(_pathSegments.join('/')) &&
              route.method == method) {
            for (var i = 0; i < route.segments.length; i++) {
              final segment = route.segments[i];
              if (segment.startsWith(':')) {
                pathParameters[segment.substring(1)] =
                    _pathSegments.elementAt(i);
              }
            }

            final poss = _find(
              pathSegments: pathSegments.skip(_pathSegments.length),
              routes: route.routes,
              parent: route,
              method: method,
              pathParameters: pathParameters,
            );

            if (poss != null) {
              return poss;
            }
          }
        } else if (_pathSegments.join('/') == route.path) {
          final _segments = pathSegments.skip(_pathSegments.length).toList();

          if (_segments.isEmpty) {
            if (route.canInvoke) {
              if (route.method == method) {
                return RouteMatch(
                  route: route,
                  pathParameters: pathParameters,
                );
              } else {
                continue;
              }
            } else {
              // If the route cannot be invoked, we need to add an empty segment
              // to the segments list to continue the search for the nested
              // route that can be invoked and is empty
              _segments.add('');
            }
          }

          return _find(
            pathSegments: _segments,
            routes: route.routes,
            parent: route,
            method: method,
            pathParameters: pathParameters,
          );
        }
      }

      return null;
    }

    return _find(
      pathSegments: segments,
      routes: routes,
      parent: null,
      method: method,
      pathParameters: {},
    );
  }

  @override
  List<Object?> get props => _$props;

  Future<Response?> _serverPublicFile(
      Route route, MutableResponseContextImpl response) async {
    final path = await File(route.fullPath).resolveSymbolicLinks();

    final file = File(path);
    if (!file.existsSync()) {
      return Response.notFound('Not Found');
    }
    final stat = file.statSync();
    final ifModifiedSince = context.ifModifiedSince;

    if (ifModifiedSince != null) {
      final fileChangeAtSecResolution = stat.modified.toSecondResolution();
      if (!fileChangeAtSecResolution.isAfter(ifModifiedSince)) {
        response
          ..removeHeader(HttpHeaders.contentLengthHeader)
          ..setHeader(
            HttpHeaders.contentLengthHeader,
            formatHttpDate(DateTime.now()),
          );

        throw UnimplementedError();
      }
    }

    final entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.notFound ||
        entityType != FileSystemEntityType.file) {
      return Response.notFound('Not Found');
    }

    final contentType = MimeTypeResolver().lookup(path);

    response
      ..setHeader(
        HttpHeaders.lastModifiedHeader,
        formatHttpDate(stat.modified),
      )
      ..setHeader(
        HttpHeaders.acceptRangesHeader,
        'bytes',
      )
      ..setHeader(HttpHeaders.contentLengthHeader, '${stat.size}');

    if (contentType != null) {
      response.setHeader(
        HttpHeaders.contentTypeHeader,
        contentType,
      );
    }

    return Response.notFound('Not Found');
  }

  /// Serves a range of [file], if [request] is valid 'bytes' range request.
  ///
  /// If the request does not specify a range, specifies a range of the wrong
  /// type, or has a syntactic error the range is ignored and `null` is returned.
  ///
  /// If the range request is valid but the file is not long enough to include the
  /// start of the range a range not satisfiable response is returned.
  ///
  /// Ranges that end past the end of the file are truncated.
  Response? _fileRangeResponse(
    RequestContext request,
    File file,
    Map<String, Object> headers,
  ) {
    final _bytesMatcher = RegExp(r'^bytes=(\d*)-(\d*)$');

    final range = request.headers[HttpHeaders.rangeHeader];
    if (range == null) return null;
    final matches = _bytesMatcher.firstMatch(range);
    // Ignore ranges other than bytes
    if (matches == null) return null;

    final actualLength = file.lengthSync();
    final startMatch = matches[1]!;
    final endMatch = matches[2]!;
    if (startMatch.isEmpty && endMatch.isEmpty) return null;

    int start; // First byte position - inclusive.
    int end; // Last byte position - inclusive.
    if (startMatch.isEmpty) {
      start = actualLength - int.parse(endMatch);
      if (start < 0) start = 0;
      end = actualLength - 1;
    } else {
      start = int.parse(startMatch);
      end = endMatch.isEmpty ? actualLength - 1 : int.parse(endMatch);
    }

    // If the range is syntactically invalid the Range header
    // MUST be ignored (RFC 2616 section 14.35.1).
    if (start > end) return null;

    if (end >= actualLength) {
      end = actualLength - 1;
    }
    if (start >= actualLength) {
      return Response(
        HttpStatus.requestedRangeNotSatisfiable,
        headers: headers,
      );
    }
    return Response(
      HttpStatus.partialContent,
      body: request.method == 'HEAD' ? null : file.openRead(start, end + 1),
      headers: headers
        ..[HttpHeaders.contentLengthHeader] = (end - start + 1).toString()
        ..[HttpHeaders.contentRangeHeader] = 'bytes $start-$end/$actualLength',
    );
  }
}

extension _DateTimeX on DateTime {
  DateTime toSecondResolution() {
    if (millisecond == 0) return this;
    return subtract(Duration(milliseconds: millisecond));
  }
}
