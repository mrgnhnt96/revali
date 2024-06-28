import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:zora_annotations/zora_annotations.dart' show DI;

void main() async {
  final handler = Cascade().add(_root()).handler;

  final server = await io.serve(handler, 'localhost', 8123);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}

Handler _root() {
  final pipeline = Pipeline()
      .addMiddleware(_prepDi())
      .addMiddleware(_middleStuff(MiddleNada('1')))
      .addMiddleware(_middleStuff(MiddleStuff('2')))
      .addMiddleware(logRequests());

  return pipeline.addHandler(_helloHandler);
}

Middleware _prepDi() => (handler) {
      return (request) async {
        request.change(context: {
          'di': DI.instance,
        });

        return handler(request);
      };
    };

Middleware _middleStuff<T extends Object>(ZoraMiddleWare<T> middleware) =>
    (handler) {
      return (request) async {
        final context = Context();

        final beforeResult = await middleware.before(context);
        if (beforeResult != null) {
          DI.instance.registerSingleton(beforeResult);
        }

        final response = await handler(request);

        final afterResult = await middleware.after(context);
        if (afterResult != null) {
          DI.instance.registerSingleton(beforeResult);
        }

        return response;
      };
    };

Response _helloHandler(Request request) {
  final name = request.url.queryParameters['name'] ?? 'You';
  print('REQUEST');
  return Response.ok('Hello, $name!');
}

class MiddleStuff extends ZoraMiddleWare<String> {
  MiddleStuff(this.message);

  final String message;

  Future<String?> after(context) async {
    print('($message) after $message');
    return null;
  }

  @override
  Future<String?> before(context) async {
    final nada = context.get<Nada>();
    print('($message) nada message: ${nada.message}');
    return null;
  }
}

class MiddleNada extends ZoraMiddleWare<Nada> {
  MiddleNada(this.message);
  final String message;

  @override
  Future<Nada> before(_) async {
    print('nada before');
    return Nada('helllo');
  }

  @override
  Future<Nada> after(_) async {
    print('nada after');
    return Nada('goodbye');
  }
}

class Nada {
  const Nada(this.message);

  final String message;
}

abstract class ZoraMiddleWare<T extends Object> {
  const ZoraMiddleWare();

  Future<T?> before(Context context) async {
    return null;
  }

  Future<T?> after(Context context) async {
    return null;
  }
}

class Context {
  const Context();

  T get<T>() {
    return DI.instance.get<T>();
  }
}
