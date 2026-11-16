<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 3.5.0

### Chore

- Support `analyzer` 13 and 14 (`>=13.3.0 <15.0.0`) and `dart_style` up to 3.1.14. `^10.0.0` held back every project that also depends on `build_web_compilers`, whose first release that allows Dart 3.14 (4.8.11) needs `analyzer >=13.3.0`. The floor moves to 13.3.0 rather than widening down to 10: analyzer 13 replaced `NamedExpression` with `NamedArgument`, and the two share no API, so a single source cannot compile against both. 13.3.0 is also where `Folder.getFile`/`getFolder` arrive.

# revali_annotations

## 3.2.0

### Features

- Add `@Consumes(topic, group:)`, marking a method as the handler for messages on a topic. `group` is required rather than defaulted: a default would have to be derived from the package or class name, and a group name that changes when code is renamed silently re-reads a stream from scratch.

# revali_construct

## 3.1.0

### Chore

- Support `analyzer` 13 and 14 (`>=13.3.0 <15.0.0`), up from `^10.0.0`. Constructs that use analyzer APIs removed in 11–13 (for example `ClassDeclaration.name`/`members`, `NamedExpression`, `Element.isSynthetic`) need migrating when they take this version.

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

## 5.3.0

### Features

- Add `CorsPolicy`, a runtime CORS policy an app supplies by overriding `cors` on `AppConfig`, or through `Router(cors: ...)`. After the `@AllowOrigins` check, `CorsPolicy.grant` decides `Access-Control-Allow-Origin` and whether `Access-Control-Allow-Credentials: true` is sent. It runs before any lifecycle component, so it governs preflights too, which nothing in an app could reach before. The default reflects the origin with credentials, as before.
- Send `Vary: Origin` on every response to a request with an `Origin` header, refusals included, so a cache cannot serve one origin's grant to another. This is the one change to existing apps' responses.

### Fixes

- Keep the CORS grant and other headers already on the response when a guard, middleware, interceptor or request wrapper throws, as a handler error already did. Without them a browser reported a network error instead of the real status.
- Stop an error response leaving one request's headers on an app-supplied `DefaultResponses` instance, where they reached later requests.

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

## 1.4.0

### Chore

- Support `analyzer` 13 and 14 (`>=13.3.0 <15.0.0`), up from `^10.0.0`. Synthetic fields are now excluded with `isOriginGetterSetter`, since `FieldElement.isSynthetic` no longer exists; the set of fields documented is unchanged.

<!-- REVALI CLIENT -->

# revali_client

## 3.1.0

### Features

- Add `isTransportError`, a predicate for `Stream.handleError(test:)` that is true only for `package:http`'s `ClientException` — the error a stream raises when the connection itself fails, most often because the peer went away. Generated stream clients use it to keep swallowing that noise without also swallowing everything else. It is deliberately not called `isDisconnectError`: `ClientException` also covers "Client is already closed" and a malformed content-length, and the name should not promise more than it delivers. Type-based, never message-matching, and imports no `dart:io`, so the package stays web-safe.

# revali_client_gen

## 2.7.0

### Chore

- Support `analyzer` 13 and 14 (`>=13.3.0 <15.0.0`) and `dart_style` up to 3.1.14, up from `^10.0.0` and `<3.1.8`.
