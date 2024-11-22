---
title: Body
description: The payload of the outgoing HTTP response
---

# Response Body

The `ResponseBody` is the object that represents the outgoing HTTP response body. Generally, the body is set by the endpoint handler, but it can also be modified by the Lifecycle Components. The body can be of any type, such as a `String`, `Map`, `List`, or a custom object.

## Structure

The body can be of any type, such as a `String`, `Map`, `List`, or a custom object. The body is serialized into a JSON string before being sent to the client.

Revali Server will wrap the body in a `Map` under the `data` key before sending it to the client. Its good practice to wrap the body under the `data` key to provide a consistent response structure.

```dart
{
    'data': body
}
```

You can set the body of the response from the endpoint handler by declaring a return type for the endpoint method.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {
    @Get()
    int count() {
        return 42;
    }
}
```

In the example above, the body of the response will be `42`.

```dart
{
    'data': 42
}
```

## Body Types

### Strings

Since Revali Server by defaults wraps the body in a `Map`, you can return a `String` from the endpoint handler, but it will still be wrapped in a `Map`.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {
    @Get()
    String hello() {
        return 'Hello, World!';
    }
}
```

In the example above, the body of the response will be `'Hello, World!'`.

```dart
{
    'data': 'Hello, World!'
}
```

To return a `String` without it being wrapped in a `Map`, change the return type to `StringContent`, which will return the `String` as is.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {
    @Get()
    // highlight-start
    StringContent hello() {
        return StringContent('Hello, World!');
    }
    // highlight-end
}
```

In the example above, the body of the response will be `'Hello, World!'`.

```plaintext
Hello, World!
```

### Custom Objects

You can return custom objects from the endpoint handler, but you need to ensure that the object can be serialized into a JSON string.

```dart
import 'package:revali_router/revali_router.dart';

class User {
    const User(this.name, this.age);

    final String name;
    final int age;

    // highlight-start
    Map<String, dynamic> toJson() {
        return {
            'name': name,
            'age': age,
        };
    }
    // highlight-end
}
```

By implementing the `toJson` method, you can control how the object is serialized into a JSON string. Revali Server will call the `toJson` method when serializing the object.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {
    @Get()
    User getUser() {
        return User('John Doe', 42);
    }
}
```

In the example above, the body of the response will be:

```dart
{
    'data': {
        'name': 'John Doe',
        'age': 42
    }
}
```

### Lists

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {
    @Get()
    List<String> getUsers() {
        return ['John Doe', 'Jane Doe'];
    }
}
```

In the example above, the body of the response will be:

```dart
{
    'data': ['John Doe', 'Jane Doe']
}
```

### Maps

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {
    @Get()
    Map<String, dynamic> getUser() {
        return {
            'name': 'John Doe',
            'age': 42,
        };
    }
}
```

In the example above, the body of the response will be:

```dart
{
    'data': {
        'name': 'John Doe',
        'age': 42
    }
}
```

### File

You can return a `File` object from the endpoint handler. The file will be streamed to the client.

```dart
import 'dart:io';

import 'package:revali_router/revali_router.dart';

@Controller('files')
class FilesController {
    @Get()
    File downloadFile() {
        return File('path/to/file.txt');
    }
}
```

:::tip
Returning files is easier than returning the file Stream directly. Revali Server will handle all the necessary headers and streaming for you.
:::

### Memory File

Occasionally, you may have the content of a file, but not the file itself. In such cases, you can use the `MemoryFile` class to create a file from the content.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('files')
class FilesController {
    @Get()
    MemoryFile downloadFile() {
        return MemoryFile.from(
            'Hello, World!',
            mimeType: 'text/plain',
            basename: 'file',
            extension: 'txt',
        );
    }
}
```

:::note
If you don't provide a basename, the default value is `file`.
:::

### Streams

You can return streams from the endpoint handler. Unless the endpoint is a `WebSocket`, the stream should be `Stream<List<int>>` (a stream of byte arrays).

```dart
import 'dart:async';

import 'package:revali_router/revali_router.dart';

@Controller('files')
class FilesController {
    @Get()
    Stream<List<int>> downloadFile() {
        return Stream.fromIterable([
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
        ]);
    }
}
```

The response headers will look like:

```dart
{
    'Content-Disposition': 'attachment; filename="file.txt"',
    'Content-Type': 'application/octet-stream',
    'Transfer-Encoding': 'chunked',
}
```

If you want to change the default filename from `file.txt`, you can set the `headers.filename` property by adding a `MutableHeaders` property to the method.

```dart
Stream<List<int>> downloadFile(MutableHeaders headers) {
    // highlight-next-line
    headers.filename = 'my-file.txt';
    ...
}
```

With the `filename` property set, the response headers will look like:

```dart
{
    'Content-Disposition': 'attachment; filename="my-file.txt"',
    'Content-Type': 'application/octet-stream',
    'Transfer-Encoding': 'chunked',
}
```
