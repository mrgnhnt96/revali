# CHANGELOG

## 3.0.1 | 09.01.26

### Fixes

- **Percent-encode query keys and values.** `RevaliClient.request` wrote every key and value into the URL verbatim and handed the result to `Uri.parse`, so any character that means something in a query string was read as syntax rather than data: a `#` truncated the value and silently moved the rest into the URI fragment, an `&` truncated it and left the remainder as a bogus extra parameter, and a `+` arrived as a space. The expensive part is where it surfaces — the client sends a request that looks fine and exits 0, and the failure appears two packages away as a deserialization error from the server, which decodes with `Uri.queryParametersAll` and so is reading exactly what it was sent. A record id containing `#` inside a JSON-encoded query parameter cut the JSON mid-string and came back as a `400` complaining about the wrong Dart type, nowhere near the call site that supplied the id. Keys and values now go through `Uri.encodeQueryComponent`, which is the exact inverse of the router's decode.
- Stop emitting an empty pair after a list or a null. The list branch wrote a `&` after *every* element while the outer loop added its own separator between entries, so `{'a': [1, 2], 'b': 3}` produced `?a=1&a=2&&b=3`; a null value skipped its pair but still got a separator. Pairs are now collected and joined, so exactly one `&` sits between them.
- Stop swallowing a `jsonEncode` failure. A value `jsonEncode` could not represent was caught and replaced with its `toString()`, putting `Instance of 'Foo'` on the wire as though it were the value and turning a mistake at the call site into a puzzling server-side error. The error now propagates.

## 3.0.0 | 08.15.26

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

## 2.1.0 | 08.13.26

### Features

- Send streamed request bodies. A `Stream<List<int>>` or `Stream<String>` body is now handed to the transport and sent incrementally, so a large upload never has to fit in memory; previously this threw `UnimplementedError`. The server side already worked — `@Body() Stream<List<int>>` reads the payload as it arrives — so this completes the round trip. `HttpRequest` gains `bodyStream`. Any other `Stream<T>` throws an `ArgumentError` naming the supported types rather than inventing a framing format the server has no binding for.

### Fixes

- Parse every `Set-Cookie` value, and stop storing cookie attributes as cookies. A response setting several cookies arrives as one comma-joined header, which `CookieParser` could not match at all, so none were saved; the attributes it did match put `Path` and `Expires` into storage. Splitting now happens only at a comma beginning a new `name=` pair, so the comma inside an `Expires` date cannot split a cookie in half.
- Actually enable cross-origin cookie credentials on web by setting `BrowserClient.withCredentials = true`, instead of adding a literal `credentials: 'include'` HTTP header (a no-op -- `credentials` is a `fetch()`-level option, not a header, so it never did anything). Non-web platforms are unaffected (no browser cookie jar to opt into).

## 2.0.5 | 08.07.26

### Fixes

- Actually enable cross-origin cookie credentials on web by setting `BrowserClient.withCredentials = true`, instead of adding a literal `credentials: 'include'` HTTP header (a no-op -- `credentials` is a `fetch()`-level option, not a header, so it never did anything). Non-web platforms are unaffected (no browser cookie jar to opt into).

## 2.0.4 | 02.18.26

### Enhancements

- Add `credentials: 'include'` to HTTP requests for cookie support with fetch

## 2.0.3 | 01.31.26

### Enhancements

- Add ability to update headers from within request interceptors

## 2.0.2 | 11.22.25

### Chore

- Sync package versions

## 1.4.0 | 05.30.25

### Features

- Support Http Interceptors
- Support clearing single keys from `Storage`

## 1.3.1 | 05.26.25

### Fixes

- Issue where matching types would not be considered equal

## 1.3.0 | 05.08.25

### Features

- Add `server_name` option to `revali.yaml#constructs.revali_client` to set the name of the server class

### Enhancements

- Add `clear` method to `Storage` class
  - Utility method to clear the cookies cache

### Fixes

- Serialize custom types in query parameters

## 1.2.0 | 04.15.25

### Features

- Add `server_name` option to `revali.yaml#constructs.revali_client` to set the name of the server class

### Enhancements

- Add check for empty query parameters before appending `?` to the URL
- Remove `final` keyword from generated server class

### Fixes

- Issue where `@ExcludeFromClient` was being ignored for interface methods
- Issue where empty controller paths would result in `//<path>` being generated in the client

## 1.1.0 | 04.07.25

### Features

- Add `ExcludeFromClient` annotation to exclude controllers/methods from being generated in the client

## 1.0.1 | 03.24.25

Initial Release!

## 1.0.0 | 03.24.25

Initial Release!
