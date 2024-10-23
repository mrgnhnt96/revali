# Request Body

The body of the request is the data that is sent by the client to the server. The body can be in many different formats, such as JSON or plain text. The body is read-only, meaning that you cannot modify the body of the request.

When the request is received by the server, the body's type is a `Stream` of bytes. Streams are a way to read data in chunks, which is useful for reading large files or data that is not fully available at once. Most of the time, you will not need to read the body as a stream, and you can read the body as a string or JSON object.

## Determining the Body Type

As the developer, you get to decide how you expect the body to be formatted. The body can be in many different formats, such as JSON, plain text, or binary data. You can determine whether you want to support multiple body types or only one.

:::tip
If you support multiple body types, you can determine the body type by looking at the `Content-Type` header of the request. The `Content-Type` header tells the server what type of data is being sent in the body.
:::

## Reading the Body

The request's body is lazy-loaded, meaning that the body is not read/resolved until you access it. This is useful because you may not need to read the body for every request, and you can save resources by not reading the body if it is not needed.

### In the Endpoint Handler

When you use the body within the your endpoint handler, Revali Server will automatically resolve the body for you. The body will be resolved as a string, JSON object, stream, etc, depending on the body's type. The value will be passed to your endpoint handler as an argument as long as the body type and the parameter type match.

```dart showLineNumbers
@Get()
Future<void> saveUser(
    // highlight-next-line
    @Body() Map<String, dynamic> data,
) async {
    ...
}
```

::::important
If the body type and the parameter type do not match, a `MissingArgumentException` will be thrown.

:::tip
Learn how to [handle exceptions][exception-catchers]
:::
::::

### Outside the Endpoint Handler

If you need to read the body within a Lifecycle Component, you can access the body using the `Request` object from the context.

The body needs to be resolved before you can access it. You can resolve the body by calling the `resolvePayload` method on the `Request` object.

:::warning
If you try to access the body without resolving it first, an `UnresolvedPayloadException` will be thrown.
:::

```dart showLineNumbers
class MyComponent implements Middleware {
    const MyComponent();

    @override
    Future<void> use(context, action) async {
        // highlight-next-line
        await context.request.resolvePayload();

        final body = context.request.body;
    }
}
```

::::note
Calling `resolvePayload` multiple times will not re-read the body, the body will be resolved and cached in memory the first time `reservePayload` is called.

:::important FYI
There are no limits to how many times you can access the body
:::
::::

Resolving the payload will check the `Content-Type` header and resolve the body as the appropriate type.

## Builtin Body Types

### String

Content-Type: `text/plain`
Dart Type: `StringBodyData`

### JSON

Content-Type: `application/json`
Dart Type: `JsonBodyData`

### Form Data

Content-Type: `application/x-www-form-urlencoded`
Dart Type: `FormDataBodyData`

### Multipart Form Data

Content-Type: `multipart/form-data`
Dart Type: `FormDataBodyData`

### Binary Data

Content-Type: `application/octet-stream`
Dart Type: `BinaryBodyData`

## Custom Body Types

If you need to support a custom body type, you can create a class that extends the `BodyData` class. Once you have created your custom body type, you'll need to register it with the `PayloadImpl`.

### Create

```dart
import 'dart:convert';

import 'package:revali_router/revali_router.dart';

base class MyBodyData extends BodyData {
  MyBodyData(
    this._bytes,
    this._encoding,
    this._headers,
  );

  final Stream<List<int>> _bytes;
  final Encoding _encoding;
  final ReadOnlyHeaders _headers;

  @override
  Stream<List<int>> get data => _bytes;

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    return requestHeaders ?? EmptyHeaders();
  }

  @override
  bool get isNull => false;

  @override
  Stream<List<int>>? read() {
    throw UnimplementedError();
  }

  @override
  String? get mimeType => 'binary/octet-stream';
}
```

### Register

You can register your custom body type within the constructor of your [AppConfig][create-an-app]

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MyApp extends AppConfig {
  MyApp() : super(host: 'localhost', port: 8083) {
    PayloadImpl.additionalParsers['binary/octet-stream'] =
        (encoding, data, headers) async => MyBodyData(data, encoding, headers);
  }
}
```

[exception-catchers]: ../lifecycle-components/6-exception-catchers.md
[create-an-app]: ../../../revali/app-configuration/10-create-an-app.md
