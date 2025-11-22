---
title: Create Your First Endpoint
description: Build your first API endpoint and see it come to life
sidebar_position: 3
---

# Create Your First Endpoint

Welcome to the heart of Revali Server! In this guide, you'll create your first API endpoint and understand how controllers work. By the end, you'll have a working "Hello, World!" API that you can call from your browser.

## Understanding Controllers

Controllers are the foundation of your API. They organize related endpoints and handle the business logic for your routes. Think of them as the "traffic directors" that decide what happens when someone visits a specific URL.

## Method 1: Using the CLI (Recommended)

The fastest way to create a controller is using the CLI we learned about earlier:

```bash
dart run revali_server create controller
```

When prompted, enter `hello` as the controller name. This will generate a complete controller file with examples and proper structure.

## Method 2: Manual Creation

If you prefer to create files manually, here's how to do it:

### Step 1: Create the Controller File

Create a new file in your `routes` directory:

```tree
lib/
└── routes/
    └── hello_controller.dart
```

:::important
**File naming rules:**

- Must end with `_controller.dart` or `.controller.dart`
- Must be inside the `routes` directory (can be in subdirectories)
- Use snake_case for file names

  :::

### Step 2: Define the Controller Class

```dart title="routes/hello_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {
  // Your endpoints will go here
}
```

**What's happening here?**

- `@Controller('hello')` tells Revali this class handles routes starting with `/hello`
- The class name can be anything, but `HelloController` is descriptive
- Import `revali_router` to access the routing annotations

## Creating Your First Endpoint

Now let's add an endpoint that returns "Hello, World!":

### Step 3: Add the Endpoint Method

```dart title="routes/hello_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
```

**Breaking it down:**

- `@Get()` makes this method respond to GET requests
- The method name `hello` becomes the route path
- Return value is automatically converted to JSON
- Full URL will be: `http://localhost:8080/api/hello`

### Step 4: Test Your Endpoint

Now you can test your endpoint! Start your server:

```bash
dart run revali dev
```

Then visit: `http://localhost:8080/api/hello`

You should see:

```json
"Hello, World!"
```

## Understanding the Magic

Let's break down what just happened:

1. **Route Mapping**: `@Controller('hello')` + `@Get()` + method name = `/api/hello`
2. **HTTP Method**: `@Get()` handles GET requests
3. **Response**: Your return value is automatically serialized to JSON
4. **URL Structure**: All routes are prefixed with `/api` by default
   - Learn how to change the route prefix in the [app configuration](/revali/app-configuration/create-an-app#global-prefix) guide.

## Adding More Endpoints

You can add multiple endpoints to the same controller:

```dart title="routes/hello_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Get()
  String hello() {
    return 'Hello, World!';
  }

  @Get('greeting')
  String greeting() {
    return 'Welcome to Revali Server!';
  }

  @Post('echo')
  String echo(String message) {
    return 'You said: $message';
  }
}
```

**Available routes:**

- `GET /api/hello` → "Hello, World!"
- `GET /api/hello/greeting` → "Welcome to Revali Server!"
- `POST /api/hello/echo` → Echoes back the message you send

## Pro Tips

:::tip
**Use descriptive method names** - they become part of your URL structure
:::

:::tip
**Start simple** - return basic data types (String, int, bool) first, then move to complex objects
:::

:::tip
**Test as you go** - use `dart run revali dev` to see changes instantly
:::

## What's Next?

Congratulations! You've created your first endpoint. Now you're ready to:

1. **[Run your server](./run-the-server.md)** - Learn about the development server and debugging
2. **Explore more features** - Add parameters, request [bodies](../request/body.md), and [error handling](../lifecycle-components/advanced/exception-catchers.md)
3. **Build real APIs** - Create controllers for your actual application needs

Ready to see your endpoint in action? Let's run the server!
