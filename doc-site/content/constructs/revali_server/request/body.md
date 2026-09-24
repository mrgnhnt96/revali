---
title: Request Body
description: How request bodies are decoded by Content-Type, read with @Body, read in lifecycle components, and extended with custom parsers
---

The request body is decoded according to its `Content-Type` header and bound to an endpoint parameter with `@Body()`. This page covers which Dart value each content type produces, file uploads, reading the body outside an endpoint, and adding parsers for other content types. The `@Body()` annotation itself is documented under [Binding](/constructs/revali_server/core/binding#body---request-body).

## Minimal example

<CodeFile name="routes/controllers/notes_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('notes')
class NotesController {
  const NotesController();

  @Post()
  Map<String, dynamic> create(@Body() Map<String, dynamic> note) {
    return {'received': note};
  }
}
```

</CodeFile>

```bash
curl -X POST http://localhost:8080/api/notes \
  -H 'Content-Type: application/json' \
  -d '{"title": "hi", "pinned": true}'
# {"data":{"received":{"title":"hi","pinned":true}}}
```

If the decoded body does not fit the parameter type, or a required body is missing, the client gets **400** (`MissingArgumentException`).

## Content types

| `Content-Type` | Decoded value | Typical parameter |
| -------------- | ------------- | ----------------- |
| `application/json` | `Map<String, dynamic>` or `List<dynamic>` (empty body gives `{}`) | a class with `fromJson`, `Map<String, dynamic>`, `List<T>` |
| `text/plain` | `String` | `String` |
| `application/x-www-form-urlencoded` | `Map<String, dynamic>`, values type-coerced | `Map<String, dynamic>`, or `@Body(['field'])` |
| `multipart/form-data` | `Map<String, dynamic>`, fields coerced, files as maps (below) | `Map<String, dynamic>` |
| `application/octet-stream` | `List<int>` | `List<int>` |
| none | Tried in order: JSON, url-encoded form, number/bool, then `String` | |
| any other | Raw byte stream, unless a [custom parser](#custom-content-types) is registered | `Stream<List<int>>` |

Type-coerced means `"1"` becomes `1` and `"true"` becomes `true`; JSON values are kept as sent.

## File uploads

Each file part of a `multipart/form-data` body becomes a map:

| Key | Value |
| --- | ----- |
| `filename` | The client's file name. |
| `bytes` | `List<int>` file contents. |
| `content` | Contents decoded as a string. |

```dart
@Post('upload')
Map<String, dynamic> upload(@Body() Map<String, dynamic> form) {
  final file = form['file'] as Map<String, dynamic>;
  return {
    'filename': file['filename'],
    'size': (file['bytes'] as List).length,
    'count': form['count'],
  };
}
```

```bash
curl -X POST http://localhost:8080/api/notes/upload \
  -F 'file=@notes.txt' -F 'count=1'
# {"data":{"filename":"notes.txt","size":19,"count":1}}
```

Multipart parts are buffered in memory. For large uploads, send the file as `application/octet-stream` and bind the unbuffered stream:

```dart
@Post('raw')
Future<int> raw(@Body() Stream<List<int>> bytes) async {
  var size = 0;
  await for (final chunk in bytes) {
    size += chunk.length;
  }
  return size;
}
```

`@Body() Stream<List<int>>` cannot take a key path.

## Reading the body in lifecycle components

The body is decoded lazily. Outside an endpoint, call `resolvePayload()` before reading `request.body`; otherwise an `UnresolvedPayloadException` is thrown. Resolving twice does not re-read the stream.

```dart
import 'package:revali_router/revali_router.dart';

class LogBody implements LifecycleComponent {
  const LogBody();

  Future<MiddlewareResult> logBody(Request request) async {
    await request.resolvePayload();
    print(request.body.data);

    return const MiddlewareResult.next();
  }
}
```

## Custom content types

Register a `BodyParser` for a MIME type to decode it yourself. The parser returns a `BodyData`:

```dart
import 'dart:convert';

import 'package:revali_router/revali_router.dart';

final class CsvBodyData extends BodyData {
  CsvBodyData(this.data);

  @override
  final List<List<String>> data;

  @override
  String? get mimeType => 'text/csv';

  @override
  bool get isNull => false;

  @override
  Stream<List<int>>? read() => Stream.value(
        utf8.encode(data.map((row) => row.join(',')).join('\n')),
      );

  @override
  Headers headers(Headers? requestHeaders) =>
      requestHeaders ?? EmptyHeaders();
}

final class CsvBodyParser extends BodyParser {
  const CsvBodyParser() : super('text/csv');

  @override
  Future<BodyData> parse(
    Encoding encoding,
    Stream<List<int>> data,
    Headers headers,
  ) async {
    final text = await encoding.decodeStream(data);
    return CsvBodyData([
      for (final line in LineSplitter.split(text)) line.split(','),
    ]);
  }
}
```

Register it in your [app](/revali/app-configuration/create-an-app) constructor:

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  MainApp() : super(host: 'localhost', port: 8080) {
    PayloadImpl.additionalParsers['text/csv'] = const CsvBodyParser();
  }
}
```

</CodeFile>

Requests sent with `Content-Type: text/csv` are now decoded by `CsvBodyParser`, and `@Body()` receives `CsvBodyData.data`.
