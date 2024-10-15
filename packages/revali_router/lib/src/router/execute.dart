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
        :catchers,
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

    final errorResponse = Completer<ReadOnlyResponse?>();
    await runZonedGuarded(() async {
      try {
        await handler(context);
      } catch (e, stackTrace) {
        final response = await catchers(e, stackTrace);
        errorResponse.complete(response);
      }

      if (!errorResponse.isCompleted) {
        errorResponse.complete(null);
      }
    }, (e, stack) {
      // ignore: avoid_print
      print('''

================ !!!! WARNING !!!! ================

An uncaught exception was thrown after the handler (your endpoint's code) was resolved.
This will result in unexpected behavior and may cause the server to crash.

This is likely because the handler's return type is not a `Future`, or an asynchronous method was invoked and not awaited properly.

Please ensure that all handlers that use the `await` keyword or invoke asynchronous methods have a return of `Future`.

Error:
$e

Stack Trace:
${Trace.from(stack)}
================ !!!! WARNING !!!! ================

''');
    });

    if (await errorResponse.future case final response?) {
      return response;
    }

    await interceptors.post();

    return response;
  }
}
