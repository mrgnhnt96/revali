---
title: Body
---

# Response Body

The `ResponseBody` is the object that represents the outgoing HTTP response body. Generally, the body is set by the endpoint handler, but it can also be modified by the Lifecycle Components. The body can be of any type, such as a `String`, `Map`, `List`, or a custom object.

## Body Types

### Structure

The body can be of any type, such as a `String`, `Map`, `List`, or a custom object. The body is serialized into a JSON string before being sent to the client.

Revali Server will wrap the body in a `Map` under the `data` key before sending it to the client. Its good practice to wrap the body under the `data` key to provide a consistent response structure.

```dart
{
    'data': body
}
```

You can set the body of the response from the endpoint handler by declaring a return type for the endpoint method.

```dart
import 'package:revali/revali.dart';

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

### Strings

Since Revali Server by defaults wraps the body in a `Map`, you can return a `String` from the endpoint handler, but it will still be wrapped in a `Map`.

```dart
import 'package:revali/revali.dart';

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
import 'package:revali/revali.dart';

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

### Custom Objects

You can return custom objects from the endpoint handler, but you need to ensure that the object can be serialized into a JSON string.

```dart
import 'package:revali/revali.dart';

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
import 'package:revali/revali.dart';

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
