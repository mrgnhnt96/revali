# Handling Requests

## Request Parameters

### Accessing Body Parameters

Use the `@Body` annotation to access parameters from the request body:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/example")
class ExampleController {

  @Post('/create')
  Future<void> createItem(@Body() ExampleBody body) async {
    // Access body parameter
    print(body);
  }
}
```

### Accessing Query Parameters

Use the `@Query` annotation to access query parameters from the request URL:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/example")
class ExampleController {

  @Get('/items')
  Future<void> getItems(@Query('type') String type) async {
    // Access query parameter
    print(type);
  }
}
```

### Accessing Path Parameters

Use the `@Param` annotation to access parameters embedded in the request path:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/example")
class ExampleController {

  @Get('/items/{id}')
  Future<void> getItem(@Param('id') String id) async {
    // Access path parameter
    print(id);
  }
}
```

### Accessing Header Parameters

Use the `@Header` annotation to fetch values from the request headers:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/example")
class ExampleController {

  @Get('/auth')
  Future<void> authenticateUser(@Header('Authorization') String authHeader) async {
    // Access header parameter
    print(authHeader);
  }
}
```

## Response Handling

### Return Types and Status Codes

You can control the return type and status code of your responses by returning appropriate types from your controller methods:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_router/revali_router.dart';

@Controller("/example")
class ExampleController {

  @Get('/success')
  Future<Response> successResponse() async {
    return Response(200, body: 'Success');
  }

  @Get('/not_found')
  Future<Response> notFoundResponse() async {
    return Response(404, body: 'Not Found');
  }
}
```

### Custom Responses

For more complex responses, you can create custom response objects and return them:

```dart
import 'package:revali_router/revali_router.dart';

@Controller("/example")
class ExampleController {

  @Get('/custom')
  Future<Response> customResponse() async {
    final customBody = {'message': 'Hello, World!'};
    return Response(200, body: customBody, headers: {'Content-Type': 'application/json'});
  }
}
```
