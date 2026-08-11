---
title: Create Your First Endpoint
description: Create a new controller and endpoint
---

This guide will walk you through creating your first API endpoint using Revali's approach.

<Callout type="tip">

This guide covers the core concepts of Revali. For a complete server implementation, check out the [Revali Server](/constructs/revali_server) guide.

</Callout>

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

<CodeFile name="routes/hello_controller.dart">

```dart
import 'package:revali_annotations/revali_annotations.dart';

@Controller('hello')
class HelloController {
  // Your endpoints will go here
}
```

</CodeFile>

<Callout type="important">

**File Naming Requirements:**

- Controller files must end with `_controller.dart` or `.controller.dart`

- Files must be placed in the `routes` directory (can be nested in subdirectories)

</Callout>

## Add Your First Endpoint

Now let's add a simple endpoint that returns "Hello, World!":

<CodeFile name="routes/hello_controller.dart">

```dart
import 'package:revali_annotations/revali_annotations.dart';

@Controller('hello')
class HelloController {
  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
```

</CodeFile>

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

<CodeFile name="routes/hello_controller.dart">

```dart
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

</CodeFile>

This creates three endpoints:

- `GET /api/hello/hello`
- `GET /api/hello/greet`
- `POST /api/hello/echo`

## Next Steps

<Callout type="tip">

Ready to see your API in action? Check out the [Run the Server](/revali/getting-started/run-the-server) guide to start your development server.

</Callout>

For more advanced features like:

- Request/response handling
- Middleware and guards
- Error handling
- Database integration

Check out the [Revali Server](/constructs/revali_server) documentation.
