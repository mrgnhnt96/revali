# Create Your First Endpoint

## Create a New Controller

Controllers are the entry point for your Revali application. They define the endpoints that your application will expose. To create a new controller, create a new Dart file in your project's `routes` directory. Controller's file name should end with `_controller.dart`. For example, we can create a new controller called `hello_controller.dart`:

```tree
.
├── lib
│   └── <non-revali-files>
└── routes
    └── hello.controller.dart
```

<sup>Note: The controller's file name can end in either `_controller.dart` or `.controller.dart`.</sup>

### Define the Controller

The controller file should contain a class annotated with the `Controller` annotation from the `revali_annotation` package. (Generally, this is exported by the construct you are using, `revali_server` instructs us to import `revali_router` to use the `revali_annotation` package.)

```dart
// hello.controller.dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {}
```

## Create a New Endpoint

### Define the Endpoint

Endpoints are methods within a controller that define the logic for a specific route. To create a new endpoint, add a new method to your controller class.

```dart
// hello.controller.dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  String hello() {
    return 'Hello, World!';
  }
}
```

### Expose the Endpoint

To expose this method as an endpoint, annotate it with a `Method` annotation. There are some out-of-the-box methods that you can use to define the HTTP method for the endpoint. For example, to define a `GET` endpoint, use the `Get` annotation:

```dart
// hello_controller.dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
```
