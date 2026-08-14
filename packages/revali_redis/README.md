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

```dart
final broker = await RedisBroker.connect(
  host: 'localhost',
  // Redis tracks pending entries per consumer name, so give each replica
  // its own. Two sharing a name make each other's pending work invisible.
  consumerName: Platform.environment['HOSTNAME'] ?? 'revali',
);

final consumers = ConsumerRegistry(broker: broker, di: di);

await consumers.consume(
  'order.placed',
  group: 'billing',
  onMessage: (message) async {
    // TraceContext.current is seeded from the message headers, so this stays
    // on the trace of the request that published it.
    await invoices.create(message.json);
  },
);
```

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

Register the drain so a deploy does not kill a consumer mid-message:

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

- Reconnection backs off and retries the read loop, but does not reclaim
  another consumer's abandoned entries with `XAUTOCLAIM`.
- No TLS or `AUTH` support yet.

[broker]: https://pub.dev/packages/revali_core
