# Error Handling

## Exception Filters

### Creating and Using Exception Filters

Exception filters in Revali allow you to handle errors in a centralized manner. Exception filters catch exceptions thrown during request processing and format the error responses sent back to the client.

### Creating an Exception Filter

To create an exception filter, implement the `ExceptionFilter` interface and override the `catchException` method:

```dart
import 'package:revali_router/revali_router.dart';

class MyExceptionFilter implements ExceptionFilter {
  @override
  void catchException(Exception exception, RequestContext context) {
    print('Exception caught: $exception');

    final response = Response(
      500,
      body: {'message': 'Internal Server Error'},
      headers: {'Content-Type': 'application/json'},
    );

    context.response = response;  // Set the response to be returned
  }
}
```

### Registering the Exception Filter

Register your exception filter in the `AppConfig` class:

```dart
@App(flavor: 'dev')
class DevApp extends AppConfig {
  @override
  Future<void> configureDependencies(DI di) async {
    di.registerExceptionFilter((di) => MyExceptionFilter());
  }
}
```

### Handling Specific Exceptions

You can tailor your exception filter to handle specific exceptions differently. For instance:

```dart
import 'package:revali_router/revali_router.dart';

class DetailedExceptionFilter implements ExceptionFilter {
  @override
  void catchException(Exception exception, RequestContext context) {
    if (exception is NotFoundException) {
      context.response = Response(404, body: {'message': 'Not Found'});
    } else if (exception is UnauthorizedException) {
      context.response = Response(401, body: {'message': 'Unauthorized'});
    } else {
      context.response = Response(500, body: {'message': 'Internal Server Error'});
    }
  }
}
```

### Summary

Exception filters provide a robust mechanism for handling errors within your Revali application. By defining and registering exception filters, you ensure that all exceptions are caught and handled uniformly, resulting in consistent and meaningful error responses to the client.

```dart
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}
```

You can raise exceptions within your controller methods to invoke the filters:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/auth")
class AuthController {
  @Get("/secure")
  Future<void> secureEndpoint() async {
    throw UnauthorizedException('You are not authorized');
  }
}
```
