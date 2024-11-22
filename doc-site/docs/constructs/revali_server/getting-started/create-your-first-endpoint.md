---
title: Create Your First Endpoint
description: Classes and methods are the bread and butter
sidebar_position: 2
---

# Create Your First Endpoint

## Controllers

Controllers are used to define the endpoints that your application will expose. To create a new controller, create a Dart file in your project's `routes` directory. We'll create one called `hello_controller.dart`:

```tree
.
├── lib
└── routes
    └── hello_controller.dart
```

::::important
The controller file name must end in either `_controller.dart` or `.controller.dart`.
:::note
The controller file needs to be within the `routes` directory, but can be nested within subdirectories.
:::
::::

### Define the Controller

The controller file should contain a class annotated with the `Controller` annotation from the `revali_router` package.

```dart title="routes/hello_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {}
```

## Create a New Endpoint

### Define the Endpoint

Endpoints are methods within a controller that define the logic for a specific route. To create a new endpoint, add a new method to your controller class.

```dart title="routes/hello_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  // highlight-start
  String hello() {
    return 'Hello, World!';
  }
  // highlight-end
}
```

### Expose the Endpoint

To expose this method as an endpoint, annotate it with a `Method` annotation. There are some out-of-the-box methods that you can use to define the HTTP method for the endpoint. For example, to define a `GET` endpoint, use the `Get` annotation:

```dart title="routes/hello_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  // highlight-next-line
  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
```

---

Now that you've created your first endpoint, it's time to run the server and see it in action.
