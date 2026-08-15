# Revali Redis

A [`MessageBroker`][broker] for Revali backed by **Redis Streams**.

Revali does not run a broker. Like a database, Redis is infrastructure you
deploy; this package is the client side of it.

## Why Streams, not pub/sub

Redis pub/sub is fire-and-forget: a consumer that happens to be restarting
simply misses whatever was published. That is the opposite of what a work queue
is for. Streams persist, and consumer groups give one delivery per group with
redelivery until the message is acknowledged.

## Usage

Return the broker from your app's `createBroker()`, and annotate handlers with
`@Consumes`. Revali registers them, gives each message its own trace and
request-scoped DI, and drains them on shutdown:

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: '0.0.0.0', port: 8080);

  @override
  Future<MessageBroker?> createBroker() => RedisBroker.connect(
        host: Env.current.string('REDIS_HOST', orElse: 'localhost'),
        // Redis tracks pending entries per consumer name, so give each replica
        // its own. Two sharing a name make each other's pending work
        // invisible. Worker isolates within one process are suffixed
        // automatically.
        consumerName: Env.current.string('HOSTNAME', orElse: 'revali'),
        // Recover entries a replica stranded when it died mid-message.
        claimAfter: const Duration(minutes: 2),
      );
}

@Controller('orders')
class OrdersController {
  const OrdersController();

  @Consumes('order.placed', group: 'billing')
  Future<void> onPlaced(BrokerMessage message) async {
    // TraceContext.current is seeded from the message headers, so this stays
    // on the trace of the request that published it.
    await invoices.create(message.json);
  }
}
```

`connect` forwards every tuning knob the constructor takes — `consumerName`,
`blockFor`, `batchSize`, `claimAfter`, `maxDeliveries`, `deadLetterSuffix` — so
it is the whole API rather than the easy half of it.

### Without `@Consumes`

`ConsumerRegistry` is the layer underneath, for wiring a subscription by hand:

```dart
final consumers = ConsumerRegistry(broker: broker, di: di);

await consumers.consume(
  'order.placed',
  group: 'billing',
  onMessage: (message) async => invoices.create(message.json),
);
```

A hand-rolled registry is yours to drain and close — see [Shutdown](#shutdown).

Publishing is just:

```dart
await broker.publish(
  'order.placed',
  jsonEncode(order),
  // Carries the correlation forward; see TraceContext.outboundHeaders().
  headers: TraceContext.current?.outboundHeaders() ?? const {},
);
```

## Delivery guarantees

**At least once.** A handler that succeeds but whose acknowledgement is lost
will see its message again. Handlers must be idempotent — that is the broker
contract, not a limitation of this package.

A handler that throws is not acknowledged, leaving the entry pending so it can
be redelivered.

## Shutdown

A broker returned from `createBroker()` is owned by the framework: consumers
drain before HTTP on `SIGTERM`, and the broker is closed for you. Do **not**
also drain it in `onServerStopped`.

A `ConsumerRegistry` you built yourself takes no part in that, so register its
drain so a deploy does not kill a consumer mid-message:

```dart
@override
Future<void> onServerStopped() async {
  await consumers.drain(const Duration(seconds: 15));
  await consumers.close();
}
```

`drain` **pauses** subscriptions before waiting rather than cancelling them.
Cancelling would abandon messages mid-handler, and on an at-least-once broker
every one of them is then redelivered as a duplicate nobody needed.

## Testing

The unit tests run against a fake connection and need nothing installed. The
integration tests need a real server and are skipped by default:

```bash
dart test --run-skipped --tags integration
REDIS_TEST_HOST=... REDIS_TEST_PORT=... dart test --run-skipped --tags integration
```

## Known limitations

- Reclaiming scans with `XPENDING` and takes entries over with `XCLAIM` rather
  than using `XAUTOCLAIM`, so it costs a round trip per pass. It runs only when
  a read came back empty, so that cost lands on an idle queue rather than a
  busy one.
- No TLS or `AUTH` support yet.

[broker]: https://pub.dev/packages/revali_core
