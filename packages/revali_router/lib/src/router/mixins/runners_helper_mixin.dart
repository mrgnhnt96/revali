part of '../router.dart';

mixin RunnersHelperMixin {
  RouterHelperMixin get helper;

  RunInterceptors get interceptors => RunInterceptors(helper);
  RunGuards get guards => RunGuards(helper);
  RunMiddlewares get middlewares => RunMiddlewares(helper);
  RunCatchers get catchers => RunCatchers(helper);
  RunOptions get options => RunOptions(helper);
  RunRedirect get redirect => RunRedirect(helper);
  RunOriginCheck get originCheck => RunOriginCheck(helper);
  Execute get execute => Execute(helper);

  HandleWebSocket handleWebSocket(dynamic handler) => HandleWebSocket(
        handler: handler,
        mode: (helper.route as WebSocketRoute).mode,
        ping: (helper.route as WebSocketRoute).ping,
        helper: helper,
      );
}
