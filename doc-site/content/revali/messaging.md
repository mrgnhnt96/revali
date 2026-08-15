---
title: Messaging
description: Consume messages with @Consumes, backed by a broker you deploy
---

Some work does not belong in a request. An order is placed, and three other
things have to happen — an invoice, a shipment, an email — none of which the
caller should wait for, and none of which should fail the checkout when they
break.

Revali does **not** run a broker. Like a database, the broker is infrastructure
you deploy; the framework only gives you the client side of it: a
`MessageBroker` contract, an `@Consumes` annotation that turns a controller
method into a handler, and the wiring that gives each message the same
treatment a request already gets.

## Two pieces, and both are required

Messaging is opt-in in both directions:

1. **Annotate a method** with `@Consumes(topic, group:)`. Nothing is generated
   at all when no handler is annotated — a server generated for an app without
   messaging is byte-identical to one generated before any of this existed.
2. **Supply a broker** from `AppConfig.createBroker()`. It returns `null` by
   default, and an app that returns `null` registers no consumers *even when
   handlers are annotated*.

That second point is worth holding on to. Annotating a method is not enough,
and the failure is quiet: the code compiles, the server starts, and nothing
ever arrives.

## Your first consumer

<CodeFile name="routes/controllers/orders_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('orders')
class OrdersController {
  const OrdersController();

  @Get()
  String list() => 'ok';

  @Consumes('order.placed', group: 'billing')
  Future<void> onPlaced(BrokerMessage message) async {
    await invoices.create(message.json);
  }
}
```

</CodeFile>

<CodeFile name="routes/apps/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  Future<MessageBroker?> createBroker() async => InMemoryBroker();
}
```

</CodeFile>

`createBroker` is a method rather than a getter because connecting is async.
The broker it returns is owned by the framework from that point on — it is
drained and closed as part of shutdown, so you do not register it in
`onServerStopped` yourself.

Consumers live on controllers alongside routes, and controllers are singletons
by default — so the same instance serves both. Your `@Get` handler and your
`@Consumes` handler are the same object, with the same fields. A controller
declared `InstanceType.factory` is constructed per message instead, exactly as
it is per request.

## What each message gets

A hand-rolled subscription — `broker.subscribe(...)` in `configureDependencies`
and a closure — works, and sits outside three things the framework already
does for every request:

- **Its own `TraceContext`**, seeded from the message headers. An event
  published during a request stays on that request's trace when it is handled
  minutes later in another process. Without it, the two services' logs cannot
  be joined afterwards.
- **Its own `RequestScopedDI` scope**, disposed when the message ends — the
  same lifetime a request-scoped dependency gets, rather than one long-lived
  scope shared by every message the process ever handles.
- **A place in shutdown.** A hand-rolled consumer takes no part in the drain,
  so a deploy drains HTTP properly while that consumer keeps pulling work and
  is then killed mid-message.

Publishing carries the trace forward, but only if you ask it to. Nothing
forwards headers automatically — what counts as a trusted peer is your call,
not the framework's:

```dart
await broker.publish(
  'order.placed',
  jsonEncode(order),
  headers: TraceContext.current?.outboundHeaders() ?? const {},
);
```

Headers carry *metadata* — correlation identifiers, typically. Anything a
consumer needs in order to do its job belongs in the payload.

## Guards and middleware do not run

This is deliberate, and it is the thing most likely to surprise you.

A guard exists to reject a **caller**. It answers "is this request allowed?" by
looking at who sent it — a token, a session, an IP. A message pulled off a
queue has no caller: it was published by a service that may have exited hours
ago, and there is nothing to reject. A guard that ran here would either have to
invent a principal or pass everything, and neither is a guard.

The practical consequence: **whatever you were relying on middleware for, do it
in the handler.** Authorization decisions that a route gets from a guard have
to come from the payload instead — the publisher is the one who knew who the
user was, so it is the publisher's job to put that in the message.

<Callout type="important">

A method cannot be both a route and a consumer. Generation fails, naming the
controller and method, rather than emitting something ambiguous — the two have
different lifetimes and only one of them has a request.

</Callout>

## Consumer groups

`group` is what decides who gets a copy:

- Members of **one** group share the work. Each message goes to exactly one of
  them. Two replicas of your billing service in group `billing` do not both
  create the invoice.
- **Different** groups on the same topic each get their own copy. That is how
  several services react to one event without the publisher knowing about any
  of them.

```dart
@Consumes('order.placed', group: 'billing')
Future<void> onPlaced(BrokerMessage message) async { /* ... */ }

/// A second group on the same topic: both get a copy.
@Consumes('order.placed', group: 'shipping')
void alsoOnPlaced(BrokerMessage message) { /* ... */ }
```

<Callout type="note">

`group` is required rather than defaulted. A default would have to be derived
from something — the package name, the class name — and a group name that
changes when you rename code silently re-reads the whole stream from scratch.
An explicit string is one you can rename on purpose.

</Callout>

## Delivery is at least once

**Handlers must be idempotent.** This is the broker contract, not a limitation
of any one implementation. A handler that succeeds but whose acknowledgment is
lost — the process died in the gap, the connection dropped — will see its
message again. So will a handler that threw, which is what makes retries work
at all: a handler that throws does not acknowledge, and an unacknowledged
message is redelivered.

`BrokerMessage.id` does not save you here. It is the broker's identifier for
*this delivery*, used to acknowledge it, and a broker may hand you the same
logical event twice under different ids. Deduplicate on something from your own
domain: an order id, a unique key the publisher put in the payload for exactly
this purpose, a unique constraint on the row you are about to insert.

The shape that works is almost always "make the effect safe to repeat" rather
than "detect the repeat" — an insert-or-update instead of a plain insert, a
state transition that is a no-op when the state is already reached.

## What a handler may look like

A handler takes a `BrokerMessage` or nothing at all:

```dart
@Consumes('order.refunded', group: 'billing')
void onRefunded() {
  // Sometimes you only need to know that it happened.
}
```

Anything else is rejected **at generation time**, naming the controller and
method, rather than emitting code that will not compile:

| Rejected | Why |
| --- | --- |
| More than one parameter | A consumer receives one message, not a bound request |
| A parameter that is not a `BrokerMessage` | There is no request to bind a `@Body` or `@Query` from |
| Two `@Consumes` on one method | Each topic needs its own group and its own registration; two annotations is ambiguous rather than additive |
| A method that is also a route | See the callout above |
| An empty topic or group | A group name is load-bearing; an empty one is a typo |

`message.json` decodes the payload for you, and throws when the payload is not
JSON — use `message.payload` when the producer sends something else.

## Shutdown: consumers drain before HTTP

On `SIGTERM`, the generated shutdown drains consumers **first**, then the HTTP
server, then calls `onServerStopped`.

The order is the whole point. Consumers *pull* new work. Leaving them running
while requests drain means the process keeps taking on messages it is about to
abandon — every one of which is then redelivered to another replica as a
duplicate nobody needed.

Draining **pauses** subscriptions before waiting, rather than canceling them.
Pausing stops taking new messages and lets the ones already in hand finish;
canceling outright abandons messages mid-handler, and on an at-least-once
broker those are all redelivered. A handler that throws during the drain does
not make the drain give up on the messages still running beside it.

Both waits are bounded by
[`shutdownTimeout`](/revali/app-configuration/graceful-shutdown) — the same
value, applied twice, once to the consumer drain and once to in-flight
requests. In the worst case a shutdown takes two of them, so set it against
your platform's kill grace period with that in mind.

## Testing with `InMemoryBroker`

`InMemoryBroker` keeps everything in the current process. It models the parts
of broker behavior that change how your code has to be written:

- consumer groups sharing work
- separate groups each getting a copy
- redelivery when a handler throws (`redeliver: false` turns this off, but the
  default is on — a local setup that quietly drops failures teaches the wrong
  lesson)
- messages published before anyone subscribed are held, not dropped

It models none of the parts that make a real broker useful: nothing survives a
restart, and nothing crosses a process boundary.

A test needs a handle on the same broker the server subscribed to, so a test
flavor of the app hands it out:

<CodeFile name="routes/apps/test_app.dart">

```dart
/// The broker the generated server subscribes to.
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

Publishing into it then drives the handler, with no socket and no server
anywhere:

```dart
test('subscribes the annotated handler', () async {
  final server = TestServer();
  await createServer(server);

  await TestBroker.instance!.publish('order.placed', 'placed');

  expect(OrdersController.handled.single.payload, 'placed');
});
```

`InMemoryBroker.published` holds every message it accepted, in order, which is
usually the easiest thing to assert on when the code under test is the
*publisher*.

## Redis, with `revali_redis`

[`revali_redis`][revali-redis] implements `MessageBroker` on top of **Redis
Streams**. It speaks the Redis wire protocol over a socket with no third-party
client, so it adds no dependency beyond `revali_core`.

```yaml
dependencies:
  revali_redis:
```

```dart
@override
Future<MessageBroker?> createBroker() => RedisBroker.connect(
      host: Env.current.string('REDIS_HOST', orElse: 'localhost'),
      // Give each replica its own name; see below.
      consumerName: Env.current.string('HOSTNAME', orElse: 'revali'),
    );
```

### Streams, not pub/sub

Redis pub/sub is fire-and-forget. A consumer that happens to be restarting
simply misses whatever was published, which is the opposite of what a work
queue is for. Streams persist, and consumer groups give exactly the semantics
the contract describes: one delivery per group, redelivery until the message is
acknowledged.

The consumer group is created together with the stream, so a consumer may start
before anything has ever been published — otherwise the deploy order between
two services would decide whether either of them works. A group that already
exists is not an error either, so the second replica to start is fine.

### Name your replicas

Redis tracks unacknowledged entries **per consumer name**. Two replicas sharing
one name make each other's pending work invisible, so the default `'revali'` is
a placeholder you should replace — a pod name or hostname is the usual choice.

<Callout type="note">

Worker isolates are told apart for you. Consumers register in every isolate, so
an app with `AppConfig.workers` greater than 1 would otherwise have every worker
subscribe under the same name and hide the others' pending entries — the exact
failure this section is about, reached without doing anything wrong. The
generated server publishes which isolate it is, and `RedisBroker` appends that
index: the parent keeps the name you configured, and the workers become
`orders-7f4c-1`, `orders-7f4c-2`, and so on.

The parent is deliberately left alone rather than becoming `-0`, so upgrading an
existing deployment does not rename its consumer and strand whatever was pending
under the old name.

You still have to give each **replica** its own name; nothing outside the process
can be guessed from inside it.

**Writing your own broker?** This is not something the framework can do for
you — it never sees the name, because your implementation builds it. Run it
through `IsolateIdentity.scopeName` and you get the same behaviour:

```dart
class MyBroker implements MessageBroker {
  MyBroker({String consumerName = 'my-service'})
      : consumerName = IsolateIdentity.scopeName(consumerName);

  final String consumerName;
  // ...
}
```

`createBroker()` runs in **every** isolate, so a broker that passes its
configured name through untouched has every worker claiming to be the same
client — and on any broker that tracks unacknowledged work per client, that
collision is silent.

</Callout>

### Reclaiming what a dead replica left behind

Because pending entries are tracked per consumer name, a replica that dies
mid-message strands its entries in a list nobody else reads. A pod that is
*replaced* rather than restarted never comes back to claim them, so they sit
there forever.

`claimAfter` fixes that: an entry idle longer than that duration is taken over
by another consumer.

```dart
await RedisBroker.connect(
  host: Env.current.string('REDIS_HOST', orElse: 'localhost'),
  consumerName: 'orders-7f4c',
  claimAfter: const Duration(minutes: 2),
  maxDeliveries: 5,
);
```

`connect()` takes every option the constructor does — `blockFor`, `batchSize`,
`claimAfter`, `maxDeliveries`, `retryAfter` and `deadLetterSuffix` — each with
the same default. Constructing `RedisBroker` directly is still supported, but it means
supplying a `ReconnectingRedisConnection` for the control link and a factory that
opens one per subscription, which is the wiring `connect()` exists to do: each
subscription needs its own connection, because a blocking read on a shared one
would stall every publish behind a consumer waiting for work.

`claimAfter` is **off by default**, because it changes when a message is
redelivered. Set it well above the time a healthy handler takes: too low and a
slow handler's work is taken out from under it and processed twice.

Reclaiming prefers a read that came back with no fresh work, as does the retry
of your own pending entries. Both are repair paths, and running them between
every batch would spend round trips on bookkeeping instead of on the queue.

That preference has a floor, though, because "only when idle" is a promise the
busy case breaks: a queue with work always waiting never *has* an idle pass, so
for as long as the load lasted a failed message was never retried and never
dead-lettered. However busy it gets, the repair paths now run at least once per
`retryAfter` (or per `blockFor`, whichever is longer) — nothing can come due
sooner than that anyway.

### Backing off between retries

`retryAfter` (default 5 seconds) is how long a failed entry waits before this
consumer tries it again.

Without it, redelivery runs as fast as the read loop: fail, notice, claim, fail
again. A handler whose dependency is thirty seconds into a restart spends its
entire `maxDeliveries` allowance inside that window, and a message that would
have succeeded on the next attempt is dead-lettered instead. The wait is what
makes a retry a second chance rather than a second reading of the same instant.

The wait **doubles with each delivery already made**, capped at 32× so a large
`maxDeliveries` cannot push the last attempt days out. At the default the
attempts land roughly 5s, 10s, 20s and 40s after the first failure.

It is measured against Redis's own idle time for the entry — the time since it
was last delivered — not against a timer in the process. A consumer that
restarts therefore reads the same schedule the old one was working to, instead
of starting every entry's wait over.

`Duration.zero` retries at the speed of the read loop. Dead-lettering is never
delayed by the backoff: an entry with no allowance left has nothing to wait for.

### Dead letters

Reclaiming on its own turns a message that *always* fails into a retry storm:
claimed, failed, left pending, claimed again, forever. `maxDeliveries` (default
5) is the escape hatch.

It is the **total** number of deliveries, counted the way Redis counts them and
including the first: at `5`, a handler that always throws runs five times and
the sixth pass dead-letters instead of retrying. The message is copied to
`<topic>.dead` — `order.placed.dead` for `order.placed` — with headers
recording why and where it came from, and only then acknowledged on the
original topic.

Acknowledging *after* the copy, rather than before, means a failed copy leaves
the entry pending rather than losing it.

`maxDeliveries` applies whether or not `claimAfter` is set. Retrying your own
failed messages is always on; `claimAfter` only governs taking over entries
*another* consumer abandoned.

Nothing consumes `<topic>.dead` for you. Point a consumer at it, or read it by
hand when something looks wrong — the value is that the message is somewhere a
human can look at it while the queue moves on.

### Surviving a Redis restart

A Redis restart used to kill the process outright, and it took three separate
fixes to stop it:

1. **The write error escaped.** A socket's write errors do not arrive on its
   read stream — they surface on `done`. With nothing observing that, writing
   to the dead socket raised an unhandled `SocketException` and took the
   process down.
2. **The link was never reopened.** A connection now reopens and retries once.
   A protocol error from Redis is rethrown untouched, since that is the server
   *answering* rather than the link failing.
3. **The consumer group was never recreated.** A server that restarts without
   persistence loses the group, so every later read is refused while the
   connection looks perfectly healthy — a consumer silently dead and reporting
   nothing. The read loop now recreates the group and carries on, backing off
   so a server that is still coming up does not get hammered.

The recreated group starts reading from the **beginning** of the rebuilt
stream, not from "whatever arrives next". That matters more than it sounds:
recovery races the next publish, and a message that lands before the group is
back would otherwise fall outside it and be delivered to nobody — with the
publish succeeding and the consumer looking fine. The stream was emptied by the
same restart, so reading from the start can only ever replay what arrived after
it.

### Current limitations

- No TLS, and no support for password authentication yet.
- Reclaiming scans pending entries explicitly rather than using Redis's own
  auto-claim command.

## What's next?

- [Graceful Shutdown](/revali/app-configuration/graceful-shutdown) — the drain consumers take part in
- [Request-Scoped Dependencies](/revali/app-configuration/request-scoped-dependencies) — the same scope each message gets
- [Testing](/revali/testing) — driving the generated server in-process

[revali-redis]: https://pub.dev/packages/revali_redis
