<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 3.3.2

### Fixes

- **A file the analyzer could not read was recorded as a file that did not exist.** Setting up the analysis workspace mirrored every file in the project, its dependencies and the whole Dart SDK through a single unbounded `Future.wait`, each branch ending in `catch (_) { return null }`, and a null was then skipped when populating the overlay. Every in-flight read holds a file descriptor, so on a default limit — 256 on macOS, 1024 on most Linux distributions — the fan-out exhausted it and every read that lost was silently dropped: measured against this repository's own test suite, 2772 of 3787 files at a 1024 limit, among them every SDK source and the `libraries.dart` that tells the analyzer what `dart:core` is. The SDK is mirrored last, so it does not lose a coin toss, it loses every time — which is why the symptom presented as a corrupt SDK or an inexplicable `Target of URI doesn't exist` rather than as an I/O limit, and why it followed the machine rather than the project. Reads are now bounded, so descriptor use no longer scales with the size of the workspace. A path that genuinely does not exist is still skipped, since these lists come from a filesystem walk that races with ordinary edits; every other failure is reported, and a failed **SDK** read now aborts initialization outright instead of proceeding against a partial SDK and blaming the result on your code.
- Mirror only the part of the SDK the analyzer can read — `lib/` and `version`, excluding `*.dill`, which is kernel for the VM and the web compilers rather than an analyzer summary. The previous walk pulled in `bin/` as well: the VM itself, the AOT snapshots and the bundled DevTools assets, none of which any analysis has ever opened. That is 610 files and 550.4 MiB reduced to 459 and 8.1 MiB, and because the overlay never evicts, the difference was resident for the entire life of a `revali dev` session rather than momentary. Initializing against this repository's test suite now peaks at roughly 4.5 GB where it previously peaked at roughly 6.7 GB.
- Say so when a file cannot be checked for analysis errors. The same `catch (_)` sat on the error scan, whose empty result is what gates code generation — so a file that could not be analyzed was indistinguishable from a file with nothing wrong with it, and a run that had checked almost nothing reported a clean project and generated against it.

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

## 5.1.1

### Fixes

- **A `5xx` an application wrote on purpose was discarded in a released build.** Every deliberate-refusal path — an `ExceptionCatcher` returning `.handled(statusCode: 503, body: …)`, an uncaught `HttpError` carrying its own status and envelope, a middleware's `.stop()`, a guard's `.block()` — was formatted by the same helper that formats a crash no catcher claimed, and by the time it arrived there the two were indistinguishable: at or above `500` with `debug` off, the authored response was dropped and the client answered with `Internal Server Error`, `text/plain`, 21 bytes. Refusing to leak an internal crash is right; applying it to a response the app decided on is not. `revali_server` only emits `debug: true` when the build is **not** a release, so `revali dev` showed the correct `503` and its envelope every time and the substitution appeared at exactly the moment nobody was watching it closely. `HttpError.internal` was the sharpest edge — a documented constructor whose `code` could never reach a client in production, which defeats the branch-on-a-code feature for exactly the status range it names. The helper is now two: one for a failure the application never spoke for — an unclaimed exception, a missing handler, a payload that would not parse — which still substitutes, and one for a response the application authored, which is delivered as written. Claiming a failure without supplying a status, headers or a body authors nothing, so a bare `ExceptionCatcherResult.handled()` still receives the generic `500` and every existing client of that shape is unaffected. Logging is unchanged: a `5xx` still reaches the operator on both paths.

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

## 3.0.0

### Breaking Changes

- `HttpInterceptor.onRequest` and `onResponse` return `FutureOr<HttpResponse?>` instead of `void`. Returning `null` — the common case — means "carry on"; returning a response from `onRequest` answers without sending anything, and from `onResponse` substitutes what arrived. The old signature made retries, caching and circuit breaking impossible to build **at all**, by us or by anyone else, which is why this changes now rather than after more code depends on it. Migration is mechanical: change the return type and add `return null`.
- Interceptor errors are no longer swallowed. A throwing interceptor now fails the request instead of letting it continue in whatever half-prepared state it was left in — a failed auth interceptor previously put an unauthenticated request on the wire and surfaced as a puzzling `401` from the peer rather than an error where it actually broke.

### Features

- Add `RevaliClient.timeout`. Covers reaching the far side and getting its status back, not the time spent streaming a large body afterwards — a slow download is not the same failure as a peer that never answers. Null keeps the previous unbounded behaviour, which is a poor default in a service mesh: a peer that accepts connections and never replies otherwise holds the request forever.
- Add `RetryPolicy` and `RevaliClient.retry`, **off by default**. Two rules keep it honest: only idempotent methods (`GET`, `HEAD`, `OPTIONS`, `PUT`, `DELETE`), because retrying a `POST` that reached the server and failed on the way back creates the resource twice; and only transient statuses (`502`, `503`, `504`), because a `400` will say the same thing next time and retrying it just multiplies load during an incident. A request with a streamed body is never retried at all — the stream is consumed as it is sent, so a second attempt would transmit nothing. Backoff is exponential and capped, and `Retry-After` overrides it when the server sends the delta-seconds form. Retried responses are drained, so the loop does not leak a socket per attempt.
- Retry and timeout live in `RevaliClient`, above the transport, so a custom `HttpClient` gets both instead of having to reimplement them.
- `ServerException` reads the error envelope. When the peer sent one, `code`, `reason` and `details` carry it and `isStructured` is true, so a caller can branch on `e.code == 'user_not_found'` instead of pattern-matching a body. When it did not — a plain-text response, an intermediary's HTML error page, a third-party API — those are null and the raw `body` is available exactly as before. Parsing is best-effort by design: a malformed body surfaces as the HTTP failure it already is, never as a `FormatException` from the client.
- Add `HeaderInterceptor`, which computes headers per request instead of fixing them when the client is built. The motivating case is correlation: a server handling a request and calling a peer forwards its trace headers with `HeaderInterceptor(() => TraceContext.current?.outboundHeaders() ?? const {})`. It never overwrites a header the call site set explicitly. The callback is deliberately the coupling — `revali_client` runs on the web, where `dart:io` and so `revali_core` cannot follow, so a function of `Map<String, String>` connects the two without dragging a server-only dependency into a browser bundle.

### Fixes

- Build the outgoing request *after* the interceptors run, so one that rewrites the body or the encoding is reflected in what is actually sent rather than only its headers.
- Stop the error path throwing a `TypeError` instead of reading the body. `response.stream.transform(utf8.decoder)` fails when the transport hands back a `Stream<Uint8List>` — which `package:http` does — because `transform` is generic on the stream's runtime type. Only the error path decodes a body this way, and no test exercised an error response through a generated client, so every structured failure surfaced as `type 'Utf8Decoder' is not a subtype of ...` rather than as a `ServerException`. Found by the new `test_suite/constructs/revali_client/errors` package.

# revali_client_gen

## 2.5.0

### Fixes

- Stop dropping an endpoint's own parameters when several share a Dart type. `ClientMethod.allParams` deduped its whole merged parameter list by *binding* — position, type and access, never name — and on a match **replaced** the entry it had, so one parameter per distinct Dart type survived: the last one declared. A route with `@Query() double latitude, @Query() double longitude, @Query() int? downPaymentCents, @Query() int? termPeriods, @Query() int? unitIndex` generated a client sending only `longitude` and `unitIndex`. `@Header()` collapsed the same way. The dedupe exists to reconcile a guard or interceptor's parameters against the endpoint's, and it is now confined to that: lifecycle parameters are still dropped when the endpoint already declares the same binding, but the endpoint's own list is passed through untouched. The expensive part was that adding a parameter deleted a *different* one — adding `unitIndex` silently removed `termPeriods` — with no warning, exit 0, and a client that compiles and type-checks while no longer sending a value the server still reads; a `required` parameter dropped this way fails at runtime, nowhere near the generator. Reported against 2.4.0. No `test_suite/constructs/revali_client` route declared two query parameters of one type, which is why it shipped.
- Raise the `revali_client` floor to `^3.0.0`. Nothing else in this package changed; it is re-released so the published set still resolves. `revali_client` 3.0.0 is a new major, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 2.4.0 behind on `^2.1.0` would make it unresolvable alongside it. Generated client packages are unaffected: `pubspec_file.dart` resolves `revali_client` by path rather than by version constraint.
