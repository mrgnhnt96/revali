import 'package:revali_router/revali_router.dart';

// Learn more about Lifecycle Components at https://www.revali.dev/constructs/revali_server/lifecycle-components/components
class Continue implements LifecycleComponent {
  const Continue({required this.type});

  final MiddlewareType type;

  MiddlewareResult authHandler(
    @Header() String auth,
    MutableHeaders headers,
    DataHandler data,
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

  MiddlewareResult authHandler(
    MutableHeaders headers,
    DataHandler data,
  ) {
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
    return MiddlewareResult.stop(
      body: message,
    );
  }
}

enum MiddlewareType {
  read,
  write,
}
