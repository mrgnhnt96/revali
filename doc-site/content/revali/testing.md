---
title: Testing
description: Drive your generated server in-process with revali_test
---

Revali servers are tested with [`revali_test`][revali-test], which gives you a
`TestServer` that stands in for a real `HttpServer`. Your generated server runs
in-process: no socket is bound, no port is chosen, and requests go straight to
the router. Tests stay fast and can run concurrently.

## Setup

Add `revali_test` and `test` as dev dependencies:

```yaml
dev_dependencies:
  revali_test:
  test:
```

## The basic pattern

Hand a `TestServer` to the generated `createServer`, then send requests to it:

```dart
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  late TestServer server;

  setUp(() async {
    server = TestServer();
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

`createServer` is generated into `.revali/server/server.dart`, so the import is
relative to your test file. Run `revali dev --generate-only` at least once
before running tests, or the file won't exist yet.

<Callout type="important">

Always `await createServer(server)`. `TestServer` buffers requests until
`createServer` starts listening, so a missing `await` usually still passes —
until a test sends a request fast enough to lose the race.

</Callout>

## Two things that surprise people

Both come from framework defaults rather than from your handler:

- The default URL prefix is **`/api`**, so a controller at `hello` is reached at
  `/api/hello`. Change it with `AppConfig.prefix`.
- Successful JSON responses are wrapped as **`{"data": ...}`** unless the
  handler takes over the body. That is why the example above expects
  `{'data': 'Hello world!'}` and not the bare string.

## Sending requests

`send` covers the ordinary cases:

```dart
final response = await server.send(
  method: 'POST',
  path: '/api/users',
  headers: {'x-request-id': 'abc'},
  cookies: {'session': 'token'},
  body: {'name': 'Ada'},
);
```

`response.body` is decoded for you — JSON is parsed into maps and lists,
anything else comes back as a string, and an empty body is `null`.

## Asserting headers

`response.headers.values` is a plain map, which pairs well with draining it as
you assert. Whatever is left over is a header you did not expect:

```dart
final headers = {...response.headers.values};

expectRecentHttpDate(headers.remove('date'), parsed: response.headers.date);

expect(headers.remove('content-type'), 'application/json');
expect(headers.remove('content-length'), '23');
expect(headers, isEmpty);
```

`expectRecentHttpDate` exists because a `Date` header changes on every run. It
checks the value is a well-formed HTTP date close to now, so you can assert on
it without the test failing a second later.

## Streaming: SSE and WebSockets

Use `connect` instead of `send`. It returns the stream of chunks the server
pushes back:

```dart
test('streams events', () async {
  final stream = server.connect(method: 'GET', path: '/api/events');

  final responses = await stream.toList();

  expect(responses, [
    utf8.encode(jsonEncode({'data': 'Hello world!'})),
  ]);
});
```

Chunks arrive as raw `List<int>`, so decode them with `utf8.decode` when you
want to assert on text.

## Testing against a real socket

Passing no arguments to `createServer` binds an actual `HttpServer`, which is
what you want when the thing under test *is* the transport — dual-stack
binding, TLS, or a real `HttpClient` round trip:

```dart
late HttpServer httpServer;

setUp(() async {
  httpServer = await createServer();
});

tearDown(() async {
  await httpServer.close(force: true);
});
```

Prefer `TestServer` for everything else. It is faster, needs no port, and will
not collide with another test running at the same time.

## What's next?

- [Middleware](/revali/tutorials/middleware) — the components your tests will exercise
- [Error Handling](/revali/tutorials/error-handling) — assert on the responses your catchers produce
- [`revali dev`](/revali/cli/dev) — regenerate `.revali/server/server.dart`

[revali-test]: https://pub.dev/packages/revali_test
