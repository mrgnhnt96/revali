<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 3.3.3

### Fixes

- **`dart run revali dev --generate-only` exited 0 no matter what happened.** It emitted a server against source that does not even parse and reported success: appending one line of invalid Dart to a route file printed 14 analysis errors, wrote the server anyway, and exited 0. Anything reading that exit code as the verdict — a CI step, a pre-push hook, a script that regenerates before running the suite — was reading a constant, and the real failure only surfaced later as a compile error in whatever consumed the generated output, at which point it no longer points at the generator. Generation now stops on analysis errors and reports them, which is what the watch path already did on every reload and file change.
- Propagate the construct runner's exit code. `ConstructEntrypointHandler.run` collected the value the constructs isolate reported and then returned void, so `revali dev`, `revali build` and `revali routes --generate` each awaited it and returned a literal 0 — no failure inside the construct runner could reach the shell. Two smaller holes in the same path went with it: the error listener's guard never fired, because it tested for `0` on a field that is null until the isolate reports something, so an isolate that errored before sending anything read as success; and `revali routes --generate` went on to read the manifest after a failed generation, reporting on whatever the previous run had left on disk.

# revali_annotations

## 3.2.0

### Features

- Add `@Consumes(topic, group:)`, marking a method as the handler for messages on a topic. `group` is required rather than defaulted: a default would have to be derived from the package or class name, and a group name that changes when code is renamed silently re-reads a stream from scratch.

# revali_construct

## 3.0.0

### Breaking

- Remove `GenerateConstructType.buildAndConstructs`. It could not honour its name: it reported `isBuild`, and the generator branches `if (isBuild) { build makers } else { server and other makers }`, so it took the build branch and silently skipped every construct — the opposite of "both". `revali build` passed it nowhere, but a hidden `--type buildAndConstructs` looked like the way to make a build regenerate the client, and quietly did nothing of the sort. The promote step had a matching `isBuild && isConstructs` branch written for the promise rather than the behaviour, replacing the whole `.revali` tree with outputs that phase never generated; it was unreachable and is gone too. The two remaining values are mutually exclusive, which is what the generator always assumed. Running both phases is the caller's job — `revali build` now does it explicitly, in order.

### Features

- Add `MetaConsumer` and `MetaRoute.consumers`, describing methods annotated with `@Consumes` so constructs can generate against them. Kept separate from `MetaMethod` rather than folded into it: a consumer has no HTTP verb, no path and no request to bind from, so every field they would share is one that does not apply.

# revali_core

## 3.2.0

### Features

- Add `IsolateIdentity.scopeName`, the one line a `MessageBroker` needs to avoid naming every worker the same thing. The framework cannot do this for an implementation — it never sees the name, because the implementation builds it — so `RedisBroker` being correct did nothing for a broker written elsewhere, and `revali_core` published the isolate index while saying nothing about the obligation that comes with it. `scopeName` is now that obligation in one call, documented on `MessageBroker` and `AppConfig.createBroker()` where an implementer is actually looking. It leaves the parent (index `0`) untouched rather than suffixing it `-0`, so upgrading an app that never spawns workers does not rename its consumer and strand whatever was pending under the old name.
- Document on `AppConfig.createBroker()` that it runs in **every** isolate rather than once for the process. That is what makes a name-keyed broker collide with itself, and nothing said so at the place an app author overrides it.

# revali_test

## 0.1.0

### Features

- `TestHeaders.add` appends instead of overwriting, matching `dart:io`. A response setting several cookies — each needing its own `Set-Cookie` line — arrived with only the last one, so tests could not see the rest.
- `TestRequest` sends binary and streamed bodies as they are. Previously anything that was not a `String` was `jsonEncode`d, so a `List<int>` upload arrived as the *text* `"[1,2,3]"`, and a `Stream` body was read as WebSocket frames rather than a request body — leaving the request empty. WebSocket input now arrives through its own `webSocketInput` parameter, so a streamed HTTP body is expressible at all.
- First release. `revali_test` was previously `publish_to: none`, so the testing helpers the docs and the internal suite rely on were unavailable to anyone outside this repo. It exposes `TestServer`, which stands in for an `HttpServer` so a generated server runs in-process without binding a socket, plus `TestRequest`/`TestResponse`/`TestHeaders` and the `expectRecentHttpDate` matcher.

# revali_mcp

## 0.1.0

### Features

- First release. `revali_mcp` was previously `publish_to: none`, so the Cursor configuration in the repo README could not resolve for anyone outside this repo. Exposes `list_routes`, `get_route`, `doctor`, `recent_requests`, and `create_scaffold` over an MCP stdio server.

### Fixes

- Frame stdio messages by byte count rather than decoded character count. `Content-Length` counts bytes, so any message body containing a non-ASCII character left the server waiting on data that had already arrived, and it never replied. Responses are likewise written as UTF-8 bytes instead of through `stdout.write`, which re-encodes using `Stdout.encoding` and could disagree with the length already announced.

<!-- REVALI ROUTER -->

# revali_router

## 5.1.2

### Fixes

- **Refusing a request cost more than serving one.** A `5xx` the application authored on purpose — the `503` a catcher sheds load with, an `HttpError.internal` thrown deliberately, a guard's `.block()` or a middleware's `.stop()` at or above `500` — was logged with its full stack trace, unconditionally, through a bare `print`. `Trace.format` parses every frame and `print` is synchronous, so the line cost about 2ms per response in an AOT build against roughly a third of a millisecond to serve a successful request, and it was paid on exactly the path whose volume peaks when the server has the least to spare. An app with a bounded write queue measured a clean knee at its bound: successful throughput fell ~50× one step past it, and the server completed *fewer* requests in total above the knee than below, because shedding fed the saturation it was meant to relieve. There was no logger, level or switch to turn it off; the only workaround was to throw every expected `5xx` with `StackTrace.empty`, which is impossible where the throw site is not the app's. The component that chose the status already knows why, so an authored `5xx` is now logged only when `debug` is on — under `revali dev`, where the console is what the developer is watching — and delivered silently in a released build, the same way a `4xx` always was. This reverses the 5.1.1 note that a `5xx` reaches the operator on both paths: an exception no catcher claimed, a bare `ExceptionCatcherResult.handled()` that authored nothing, and every other crash still log with their trace, since that is the case the log exists for. Independently, the log line no longer parses a trace that has no frames, so an app that already throws with `StackTrace.empty` gets the cheap path too.

# revali_redis

## 0.2.0

### Features

- Back off between retries, via `retryAfter` (default 5 seconds). Redelivery previously ran as fast as the read loop — fail, notice, claim, fail again — so a handler whose dependency was thirty seconds into a restart spent its entire `maxDeliveries` allowance inside that window, and a message that would have succeeded on the next attempt was dead-lettered instead. The wait doubles with each delivery already made and is capped at 32×, so a large `maxDeliveries` cannot push the last attempt days out; at the default the attempts land roughly 5s, 10s, 20s and 40s after the first failure. It is measured against Redis's own idle time for the entry rather than a timer in the process, so a consumer that restarts reads the same schedule the old one was working to instead of starting every entry's wait over. The claim then uses that backoff as its min-idle-time rather than `0`, so an entry redelivered between the scan and the claim is refused by Redis instead of having a running handler restarted underneath it. `Duration.zero` restores the previous behaviour; dead-lettering is never delayed by it, since an entry with no allowance left has nothing to wait for.
- `RedisBroker.connect()` forwards `retryAfter` too, with the same default as the constructor — the field-by-field test against a constructor-built broker covers it, so the two cannot drift.
- `RedisBroker` scopes its consumer name through `IsolateIdentity.scopeName` rather than a private copy of the rule. Behaviour is unchanged; the point is that the rule now has one definition, and a broker written outside this repository can call the same thing instead of rediscovering the collision.

### Fixes

- **`maxDeliveries` allowed one more delivery than it named.** The check was `deliveries > maxDeliveries`, so `maxDeliveries: 3` ran the handler four times before dead-lettering. It is now the total, counted the way Redis counts it and including the first delivery: at `5`, a handler that always throws runs five times and the sixth pass dead-letters. Proved against a real Redis, which owns the counter — the integration test asserts three attempts for `maxDeliveries: 3`, and reports four if the operator is put back.
- **The repair paths starved under load.** Retrying this consumer's own pending entries, and reclaiming another's, ran only on a pass whose read came back empty — and a queue with work always waiting never has one. For as long as the load lasted a failed message was neither retried nor dead-lettered: the same silent stall the retry path was added to end, reappearing under the one condition nobody had thought to test. Draining the queue is still the priority, so they stay off the hot path until due, but there is now a floor — they run at least once per `retryAfter`, or per `blockFor` if that is longer, and nothing can come due sooner than that anyway.

<!-- CONSTRUCTS -->

# revali_docker

## 1.2.0

### Fixes

- Raise the `revali_construct` floor to `^3.0.0`. Nothing in this package changed; it is re-released so the published set still resolves. `revali_construct` is a new major this round, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 1.1.0 behind on `^2.4.0` would make it unresolvable alongside it.

<!-- SWAGGER -->

# revali_swagger_annotations

## 1.0.0

### Features

- Initial release with `@ApiInfo`, `@ApiTag`, `@ApiSummary`, `@ApiDescription`, `@ApiResponse`, `@ApiHidden`, and `@ApiType` annotations for customizing generated OpenAPI output.

# revali_swagger

## 1.3.0

### Fixes

- Raise the `revali_construct` floor to `^3.0.0`. Nothing in this package changed; it is re-released so the published set still resolves. `revali_construct` is a new major this round, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 1.2.0 behind on `^2.4.0` would make it unresolvable alongside it.

<!-- REVALI CLIENT -->

# revali_client

## 3.0.1

### Fixes

- **Percent-encode query keys and values.** `RevaliClient.request` wrote every key and value into the URL verbatim and handed the result to `Uri.parse`, so any character that means something in a query string was read as syntax rather than data: a `#` truncated the value and silently moved the rest into the URI fragment, an `&` truncated it and left the remainder as a bogus extra parameter, and a `+` arrived as a space. The expensive part is where it surfaces — the client sends a request that looks fine and exits 0, and the failure appears two packages away as a deserialization error from the server, which decodes with `Uri.queryParametersAll` and so is reading exactly what it was sent. A record id containing `#` inside a JSON-encoded query parameter cut the JSON mid-string and came back as a `400` complaining about the wrong Dart type, nowhere near the call site that supplied the id. Keys and values now go through `Uri.encodeQueryComponent`, which is the exact inverse of the router's decode.
- Stop emitting an empty pair after a list or a null. The list branch wrote a `&` after *every* element while the outer loop added its own separator between entries, so `{'a': [1, 2], 'b': 3}` produced `?a=1&a=2&&b=3`; a null value skipped its pair but still got a separator. Pairs are now collected and joined, so exactly one `&` sits between them.
- Stop swallowing a `jsonEncode` failure. A value `jsonEncode` could not represent was caught and replaced with its `toString()`, putting `Instance of 'Foo'` on the wire as though it were the value and turning a mistake at the call site into a puzzling server-side error. The error now propagates.

# revali_client_gen

## 2.5.0

### Fixes

- Stop dropping an endpoint's own parameters when several share a Dart type. `ClientMethod.allParams` deduped its whole merged parameter list by *binding* — position, type and access, never name — and on a match **replaced** the entry it had, so one parameter per distinct Dart type survived: the last one declared. A route with `@Query() double latitude, @Query() double longitude, @Query() int? downPaymentCents, @Query() int? termPeriods, @Query() int? unitIndex` generated a client sending only `longitude` and `unitIndex`. `@Header()` collapsed the same way. The dedupe exists to reconcile a guard or interceptor's parameters against the endpoint's, and it is now confined to that: lifecycle parameters are still dropped when the endpoint already declares the same binding, but the endpoint's own list is passed through untouched. The expensive part was that adding a parameter deleted a *different* one — adding `unitIndex` silently removed `termPeriods` — with no warning, exit 0, and a client that compiles and type-checks while no longer sending a value the server still reads; a `required` parameter dropped this way fails at runtime, nowhere near the generator. Reported against 2.4.0. No `test_suite/constructs/revali_client` route declared two query parameters of one type, which is why it shipped.
- Raise the `revali_client` floor to `^3.0.0`. Nothing else in this package changed; it is re-released so the published set still resolves. `revali_client` 3.0.0 is a new major, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 2.4.0 behind on `^2.1.0` would make it unresolvable alongside it. Generated client packages are unaffected: `pubspec_file.dart` resolves `revali_client` by path rather than by version constraint.
