---
sidebar_position: 1
description: Create a new controller and endpoint
---

# Create Your First Endpoint

This guide will walk you through creating your first API endpoint using Revali's approach.

:::tip
This guide covers the core concepts of Revali. For a complete server implementation, check out the [Revali Server](/constructs/revali_server/overview) construct guide.
:::

## Project Structure

First, let's set up the basic project structure. Create a `routes` directory in your project root:

```tree
.
├── lib/
│   └── main.dart
├── routes/
│   └── (your controllers will go here)
└── pubspec.yaml
```

## Create a Controller

Controllers define the endpoints that your application will expose. Create a new file called `hello_controller.dart` in the `routes` directory:

```dart title="routes/hello_controller.dart"
import 'package:revali_annotations/revali_annotations.dart';

@Controller('hello')
class HelloController {
  // Your endpoints will go here
}
```

:::important
**File Naming Requirements:**

- Controller files must end with `_controller.dart` or `.controller.dart`

- Files must be placed in the `routes` directory (can be nested in subdirectories)
  :::

## Add Your First Endpoint

Now let's add a simple endpoint that returns "Hello, World!":

```dart title="routes/hello_controller.dart"
import 'package:revali_annotations/revali_annotations.dart';

@Controller('hello')
class HelloController {
  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
```

## Understanding the Code

Let's break down what we just created:

- **`@Controller('hello')`**: Defines a controller with the base path `/hello`
- **`@Get()`**: Marks the method as a GET endpoint
- **`String hello()`**: The method that handles the request and returns a response

## Endpoint URL

With this setup, your endpoint will be available at:

```text
GET http://localhost:8080/api/hello
```

The URL structure is: `{host}:{port}{prefix}/{controller}/{method}`

- **Host**: `localhost` (default)
- **Port**: `8080` (default)
- **Prefix**: `/api` (default)
- **Controller**: `/hello` (from `@Controller('hello')`)
- **Method**: `/hello` (method name)

## Add More Endpoints

You can add multiple endpoints to the same controller:

```dart title="routes/hello_controller.dart"
import 'package:revali_annotations/revali_annotations.dart';

@Controller('hello')
class HelloController {
  @Get()
  String hello() {
    return 'Hello, World!';
  }

  @Get('greet')
  String greet() {
    return 'Greetings!';
  }

  @Post('echo')
  String echo(String message) {
    return 'Echo: $message';
  }
}
```

This creates three endpoints:

- `GET /api/hello/hello`
- `GET /api/hello/greet`
- `POST /api/hello/echo`

## Next Steps

:::tip
Ready to see your API in action? Check out the [Run the Server](/revali/getting-started/run-the-server) guide to start your development server.
:::

For more advanced features like:

- Request/response handling
- Middleware and guards
- Error handling
- Database integration

Check out the [Revali Server](/constructs/revali_server/overview) construct documentation.
