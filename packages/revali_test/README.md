# Revali Test

Test helpers for [Revali](https://pub.dev/packages/revali) servers.

`TestServer` stands in for a real `HttpServer`, so your generated server runs
in-process: no socket is bound, no port is chosen, and requests are handed
straight to the router. Tests stay fast and can run concurrently.

## Usage

Add it as a dev dependency:

```yaml
dev_dependencies:
  revali_test:
  test:
```

Pass a `TestServer` to the generated `createServer`, then send requests to it:

```dart
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  late TestServer server;

  setUp(() async {
    server = TestServer();
    // Always await -- TestServer buffers requests until createServer listens.
    await createServer(server);
  });

  tearDown(() {
    server.close();
  });

  test('returns a greeting', () async {
    final response = await server.send(method: 'GET', path: '/api/hello');

    expect(response.statusCode, 200);
    expect(response.body, {'data': 'Hello world!'});
  });
}
```

`response.body` is decoded for you — JSON is parsed, anything else comes back
as a string. Remember that successful responses are wrapped as `{"data": ...}`
unless the handler takes over the body, and that the default URL prefix is
`/api`.

### Requests

`send` covers the ordinary cases:

```dart
await server.send(
  method: 'POST',
  path: '/api/users',
  headers: {'x-request-id': 'abc'},
  cookies: {'session': 'token'},
  body: {'name': 'Ada'},
);
```

### WebSockets and SSE

`connect` returns the stream of messages the server pushes back:

```dart
final messages = server.connect(method: 'GET', path: '/api/ws');

await expectLater(messages, emits(...));
```

### Headers

`response.headers.values` is a plain map, which pairs well with draining it as
you assert:

```dart
final headers = {...response.headers.values};

expectRecentHttpDate(headers.remove('date'), parsed: response.headers.date);
expect(headers.remove('content-type'), 'application/json');
expect(headers, isEmpty); // nothing unexpected was set
```

`expectRecentHttpDate` exists because a `Date` header changes every run; it
checks the value is a well-formed HTTP date close to now.

## Documentation

Check out the [documentation](https://www.revali.dev) for more information on
how to use Revali.
