---
title: Messaging
description: Consume queue messages with @Consumes, backed by a broker you deploy (in-memory or Redis Streams)
---

Use messaging for work that shouldn't block a request, such as sending an invoice after an order is placed. Annotate a controller method with `@Consumes`, and return a broker from `AppConfig.createBroker()`. Revali doesn't run a broker itself: you deploy one, such as Redis, the same way you deploy a database.

## Setup

Messaging needs both of these. Without either one, no consumers are registered and nothing warns you:

1. A controller method annotated with `@Consumes(topic, group:)`.
2. A broker returned from `AppConfig.createBroker()`. The default returns `null`.

<CodeFile name="routes/controllers/orders_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('orders')
class OrdersController {
  const OrdersController(this._invoices);

  final InvoiceService _invoices;

  @Consumes('order.placed', group: 'billing')
  Future<void> onPlaced(BrokerMessage message) async {
    await _invoices.create(message.json);
  }
}
```

</CodeFile>

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_redis/revali_redis.dart';
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  MainApp() : super.fromEnv();

  @override
  Future<MessageBroker?> createBroker() => RedisBroker.connect(
        host: Env.current.string('REDIS_HOST', orElse: 'localhost'),
        consumerName: Env.current.string('HOSTNAME', orElse: 'revali'),
      );
}
```

</CodeFile>

The framework owns the broker from then on, and drains and closes it during shutdown. `createBroker()` runs once in every [worker isolate](/revali/app-configuration/workers).

Publish from anywhere that has the broker. Pass the trace headers so the consumer's logs can be matched to the request that published the message:

```dart
await broker.publish(
  'order.placed',
  jsonEncode(order),
  headers: TraceContext.current?.outboundHeaders() ?? const {},
);
```

## Handler Rules

- A handler takes either one `BrokerMessage` parameter or none.
- `message.json` decodes the payload and throws if it isn't JSON. `message.payload` is the raw string. `message.headers` holds metadata.
- Consumers live on controllers alongside routes and use the same controller instance. A controller with `InstanceType.factory` is created once per message.
- **Guards and middleware don't run for messages**, because a message has no caller to reject. Check authorization in the handler, using data the publisher put in the payload.
- Each message gets its own [`TraceContext`](/revali/app-configuration/tracing), taken from the message headers, and its own [request scope](/revali/app-configuration/configure-dependencies#request-scoped-dependencies).

These mistakes fail generation with an error that names the controller and method:

- more than one parameter
- a parameter that isn't a `BrokerMessage`
- two `@Consumes` annotations on one method
- a method that is both a route and a consumer
- an empty topic or group

## Consumer Groups

- Handlers in the **same group** split the messages between them: each message goes to exactly one handler. Two replicas in group `billing` don't both create the invoice.
- **Different groups** on the same topic each get their own copy of every message.

`group` has no default. A group name is a stored identity, and renaming a group re-reads the whole stream.

```dart
@Consumes('order.placed', group: 'billing')
Future<void> bill(BrokerMessage message) async { /* ... */ }

@Consumes('order.placed', group: 'shipping')   // also receives every message
void ship(BrokerMessage message) { /* ... */ }
```

## Delivery Is At Least Once

**Handlers must be idempotent.** A handler that throws doesn't acknowledge its message, so the message is delivered again. A message whose acknowledgment was lost (because the process died, for example) is also delivered again. `BrokerMessage.id` identifies one delivery, not the event, so deduplicate on an id from your own data, such as the order id. Or make the effect safe to repeat, for example with an upsert.

## Shutdown: Consumers Drain Before HTTP

On `SIGTERM`, consumers are drained first, then HTTP requests, then `onServerStopped()` runs. Draining pauses the subscriptions, so no new messages are taken, and waits for the handlers already running, for up to [`shutdownTimeout`](/revali/app-configuration/graceful-shutdown). The request drain waits for up to `shutdownTimeout` too, so shutdown can take twice that long in the worst case.

## Testing with `InMemoryBroker`

`InMemoryBroker` runs in-process. It supports consumer groups, redelivers a message when its handler throws (turn that off with `redeliver: false`), and keeps messages published before anyone subscribed. Nothing survives a restart. `published` lists every message the broker accepted.

Keep the broker in a static field in a test flavor, so the test can reach the same instance the server uses:

<CodeFile name="routes/apps/test_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

class TestBroker {
  static InMemoryBroker? instance;
}

@App(flavor: 'test')
final class TestApp extends AppConfig {
  const TestApp() : super(host: 'localhost', port: 0);

  @override
  Future<MessageBroker?> createBroker() async =>
      TestBroker.instance = InMemoryBroker();
}
```

</CodeFile>

```dart
test('handles order.placed', () async {
  final server = TestServer();
  await createServer(server);

  await TestBroker.instance!.publish('order.placed', '{"id": 1}');

  // assert on the handler's side effects
});
```

Generate with `--flavor test` so the server uses this app. See [Testing](/revali/testing).

## Redis (`revali_redis`)

[`revali_redis`][revali-redis] implements `MessageBroker` on Redis Streams. It has no dependencies other than `revali_core`.

```yaml
dependencies:
  revali_redis:
```

Every option can be passed to `RedisBroker.connect`:

| Option | Default | Description |
| --- | --- | --- |
| `host`, `port` | `localhost`, `6379` | The Redis server. |
| `consumerName` | `'revali'` | Identifies this replica to Redis. Give every replica its own name. See [below](#name-your-replicas). |
| `blockFor` | 2 seconds | How long a read waits for new messages. |
| `batchSize` | `16` | The maximum number of messages per read. |
| `claimAfter` | off | Takes over messages that another consumer has left pending for this long, for example after a replica died. Set it well above your slowest handler, or slow messages are processed twice. |
| `maxDeliveries` | `5` | Total delivery attempts, including the first. After that, the message moves to the dead-letter topic. |
| `retryAfter` | 5 seconds | The delay before retrying a failed message. It doubles with each attempt, up to 32×. `Duration.zero` retries immediately. |
| `deadLetterSuffix` | `'.dead'` | Failed messages are copied to `<topic>.dead` (with the reason in the headers) and then acknowledged. Nothing reads this topic unless you add a consumer for it. |

The broker behaves as follows:

- The consumer group is created together with the stream, so consumers can start before anything is published. Starting more replicas is safe.
- The broker reconnects when the connection drops. If Redis restarts without persistence and loses the consumer group, the broker creates the group again and keeps reading.
- TLS and password authentication aren't supported yet.

### Name Your Replicas

Redis tracks pending messages **per consumer name**. When two replicas share a name, neither can see the other's pending messages. Give each replica its own name, such as the pod name or hostname.

Worker isolates are named for you. The parent keeps the configured name, and workers get `<name>-1`, `<name>-2`, and so on. If you write your own broker, pass the name through `IsolateIdentity.scopeName(name)` to get the same behavior.

[revali-redis]: https://pub.dev/packages/revali_redis
