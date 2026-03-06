import 'package:revali_router/revali_router.dart';

// Learn more about Lifecycle Components at https://www.revali.dev/constructs/revali_server/lifecycle-components/components
class Continue implements LifecycleComponent {
  const Continue({required this.type});

  final MiddlewareType type;

  MiddlewareResult authHandler(
    @Header() String auth,
    Headers headers,
    Data data,
  ) {
    switch (type) {
      case MiddlewareType.read:
        data.add(auth);
        return const MiddlewareResult.next();
      case MiddlewareType.write:
        headers.set('X-Auth', auth);
        data.add(auth);
        return const MiddlewareResult.next();
    }
  }
}

class ItsFine implements LifecycleComponent {
  const ItsFine();

  MiddlewareResult authHandler(Headers headers, Data data) {
    const string = 'yo yo yo';
    headers.set('X-Auth', string);
    data.add(string);

    return const MiddlewareResult.next();
  }
}

class Stop implements LifecycleComponent {
  const Stop([this.message]);

  final String? message;

  MiddlewareResult authHandler() {
    return MiddlewareResult.stop(body: message);
  }
}

/// Middleware with a named constructor that uses initializer list
/// (requireAdmin set after `:`). Tests that @Auth.admin() resolves correctly.
class Auth implements LifecycleComponent {
  const Auth({this.requireAdmin = false});
  const Auth.admin() : requireAdmin = true;

  final bool requireAdmin;

  MiddlewareResult getToken(
    @Header('Authorization') String? authorization,
    Data dataHandler,
  ) {
    if (requireAdmin && authorization != 'admin-token') {
      return const MiddlewareResult.stop(body: 'Admin required');
    }
    if (authorization case final value?) {
      dataHandler.add(value);
    }
    return const MiddlewareResult.next();
  }
}

enum MiddlewareType { read, write }
