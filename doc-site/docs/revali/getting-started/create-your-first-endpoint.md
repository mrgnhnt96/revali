---
sidebar_position: 1
description: Create a new controller and endpoint
---

# Create Your First Endpoint

:::tip
This guide represents the core concepts of Revali. For a more detailed guide on how to create a Revali Server application, check out the [Revali Server][revali-server-getting-started] construct guide.
:::

## Create a New Controller

Controllers are to define the endpoints that your application will expose.

To create a new controller, create a Dart file in your project's `routes` directory. We'll create one called `hello_controller.dart`:

```tree
.
├── lib
│   └── <non-revali-files>
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

The controller file should contain a class annotated with the `Controller` annotation from the `revali_annotations` package.

```dart title="routes/hello_controller.dart"
import 'package:revali_annotations/revali_annotations.dart';

@Controller('hello')
class HelloController {}
```

:::note
Typically, the `revali_annotations` package is imported with the server construct you're using.
:::

## Create a New Endpoint

### Define the Endpoint

Endpoints are methods within a controller that define the logic for a specific route. To create a new endpoint, add a new method to your controller class.

```dart title="routes/hello_controller.dart"
import 'package:revali_annotations/revali_annotations.dart';

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
import 'package:revali_annotations/revali_annotations.dart';

@Controller('hello')
class HelloController {

  // highlight-next-line
  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
```

[revali-server-getting-started]: ../../constructs/revali_server/getting-started/create-your-first-endpoint.md