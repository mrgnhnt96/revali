part of 'router.dart';

class Execute {
  const Execute(this.helper);

  final HelperMixin helper;

  Future<Response> run() async {
    final HelperMixin(
      :route,
      :request,
      :response,
      :debugErrorResponse,
      :defaultResponses,
      context: ContextMixin(main: context),
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
      return await handleWebSocket(await handler(context)).execute();
    }

    await interceptors.pre();

    // if the user decides to create a HEAD request,
    // we still need to run the handler,
    // This is only for the case that the router is automatically
    // handling the HEAD request.
    final isHeadRequest = route.method == 'GET' && request.method == 'HEAD';

    if (!isHeadRequest) {
      final errorResponse = Completer<Response?>();
      await runZonedGuarded(() async {
        try {
          await handler(context);
        } catch (e, stackTrace) {
          final responseForError = await catchers(e, stackTrace);
          responseForError.headers.addEverything(
            response.headers.values,
          );
          errorResponse.complete(responseForError);
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

Please ensure that all handlers that use the `async`/`await` keyword or invoke asynchronous methods have a return type of `Future`.

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
    }

    await interceptors.post();

    return response;
  }
}
