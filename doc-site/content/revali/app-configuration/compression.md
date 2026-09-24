---
title: Compression
description: Gzip responses for clients that ask for them
---

Revali gzips responses by default, and only for clients that send `Accept-Encoding: gzip`. There's nothing to turn on. Change the settings on your app to tune compression, or turn it off when a CDN or reverse proxy already compresses.

A response is compressed only when all of these are true:

- The client sent `Accept-Encoding: gzip`.
- The `Content-Type` is text-based (JSON, HTML, CSS, JavaScript, XML, SVG, plain text, CSV or Markdown).
- The body is at least `minBytes` long (1024 by default).
- The response isn't already encoded, isn't partial content (`206`), and has a known length. Streaming and SSE responses aren't compressed.

Compressed responses carry `Vary: Accept-Encoding`.

## Settings

<CodeFile name="routes/apps/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  CompressionSettings get compression => const CompressionSettings(
        minBytes: 4096,
        mimeTypes: {...CompressionSettings.defaultMimeTypes, 'application/hal+json'},
      );
}
```

</CodeFile>

| Setting | Default |
| --- | --- |
| `minBytes` | `1024` |
| `mimeTypes` | `CompressionSettings.defaultMimeTypes` |

To turn compression off:

```dart
@override
CompressionSettings get compression => const CompressionSettings.disabled();
```

These settings apply only to the default response handler. A component that provides its own `ResponseHandler` must handle compression itself.
