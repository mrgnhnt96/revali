part of 'router.dart';

class Execute {
  const Execute(this.helper);

  final HelperMixin helper;

  Future<ReadOnlyResponse> call() => run();

  Future<ReadOnlyResponse> run() async {
    final HelperMixin(
      :route,
      :request,
      :response,
      :debugErrorResponse,
      :defaultResponses,
      context: ContextMixin(endpoint: context),
      run: RunMixin(
        :interceptors,
        :guards,
        :middlewares,
        :handleWebSocket,
      ),
    ) = helper;

    final handler = route.handler;
    if (handler == null) {
      return debugErrorResponse(
        defaultResponses.notFound,
        error: MissingHandlerException(
          method: request.method,
          path: request.segments.join('/'),
        ),
        stackTrace: StackTrace.current,
      );
    }

    if (await middlewares() case final response?) {
      return response;
    }

    if (await guards() case final response?) {
      return response;
    }

    if (route is WebSocketRoute) {
      return handleWebSocket(await handler(context)).execute();
    }

    await interceptors.pre();

    await runZonedGuarded(() async {
      await handler(context);
    }, (e, stack) {
      // ignore: avoid_print
      print('''

================ !!!! WARNING !!!! ================

An uncaught exception was thrown after the handler was resolved.
This will result in unexpected behavior and may cause the server to crash.

This is likely because the handlers return type is not a `Future`.

Please ensure that all handlers that use the `await` keyword or invoke asynchronous methods are returning a `Future`.

Error:
$e

Stack Trace:
${Trace.from(stack)}
================ !!!! WARNING !!!! ================

''');
    });

    await interceptors.post();

    return response;
  }
}
