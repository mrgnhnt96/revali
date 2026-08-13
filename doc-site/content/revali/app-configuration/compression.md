---
title: Compression
description: Gzip responses for clients that ask for them
---

Revali gzips responses by default. It is negotiated, so only a client that
sent `Accept-Encoding: gzip` ever receives a compressed body — turning this on
cannot break a client that did not ask.

There is nothing to enable.

## What gets compressed

A response is compressed only when all of these hold:

- The client sent `Accept-Encoding: gzip`.
- The `Content-Type` is text-shaped — JSON, HTML, CSS, JavaScript, XML, SVG,
  plain text, CSV, Markdown.
- The body is at least `minBytes` (1 KB by default).
- The response is not already encoded, and is not partial content (`206`).

Compressed responses also carry `Vary: Accept-Encoding`, so a cache in front
of the server keeps the compressed and uncompressed variants apart instead of
serving one to a client that cannot read it.

## What deliberately does not

**Bodies of unknown length**, which in practice means streaming responses and
SSE. Gzip buffers, so compressing a stream would hold back chunks the handler
meant to flush immediately — the compression would come at the cost of the
thing streaming exists for.

**Already-compressed media.** Images, video and archives come out marginally
*larger* after gzip, having spent CPU to get there.

**Small bodies.** Below roughly a packet there is nothing to save, and gzip's
own header can make a tiny response bigger.

## Tuning it

```dart
@App()
final class MyApp extends AppConfig {
  const MyApp() : super(host: 'localhost', port: 8080);

  @override
  CompressionSettings get compression => const CompressionSettings(
    minBytes: 4096,
    mimeTypes: {...CompressionSettings.defaultMimeTypes, 'application/hal+json'},
  );
}
```

## Turning it off

Worth doing when something in front of the server already compresses — a CDN,
or a reverse proxy like nginx — so you are not paying for it twice:

```dart
@override
CompressionSettings get compression => const CompressionSettings.disabled();
```

<Callout type="note">

This applies to the default response handler. A route or global component that
supplies its own `ResponseHandler` is responsible for its own compression.

</Callout>

## What's next?

- [Graceful Shutdown](/revali/app-configuration/graceful-shutdown) — the other server-wide behavior on `AppConfig`
- [Headers](/constructs/revali_server/response/headers) — setting response headers yourself
