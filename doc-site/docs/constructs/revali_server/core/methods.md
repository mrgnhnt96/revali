---
description: HTTP methods define how your endpoints respond to requests
sidebar_position: 1
---

# HTTP Methods

HTTP methods (also called verbs) define the behavior and purpose of your API endpoints. They tell clients what action they can perform and what to expect in return.

## What Are HTTP Methods?

Think of HTTP methods as **instructions** for your API:

- **GET** - "Show me something" (retrieve data)
- **POST** - "Create something new" (submit data)
- **PUT** - "Replace this entirely" (update all data)
- **PATCH** - "Update just this part" (partial update)
- **DELETE** - "Remove this" (delete data)
- **SSE** - "Stream data to me" (real-time updates)
- **WebSocket** - "Let's chat" (bidirectional communication)

## Available Methods

Revali provides these method annotations:

| Annotation     | HTTP Method        | Purpose                     | When to Use                          |
| -------------- | ------------------ | --------------------------- | ------------------------------------ |
| `@Get()`       | GET                | Retrieve data               | Reading resources, fetching lists    |
| `@Post()`      | POST               | Create new data             | Creating resources, form submissions |
| `@Put()`       | PUT                | Replace entire resource     | Complete updates                     |
| `@Patch()`     | PATCH              | Partial updates             | Modifying specific fields            |
| `@Delete()`    | DELETE             | Remove data                 | Deleting resources                   |
| `@SSE()`       | Server-Sent Events | Real-time streaming         | Live updates, notifications          |
| `@WebSocket()` | WebSocket          | Bidirectional communication | Chat, real-time collaboration        |

:::important
You can only use **one method annotation per endpoint**.
:::

## Basic Usage

### Simple Endpoint

```dart
@Controller('api')
class ApiController {
  @Get()
  String getInfo() {
    return 'API is running';
  }
}
```

**Result:** `Controller('api')` + `Get('')` = `GET /api`

### Custom Path

```dart
@Controller('api')
class ApiController {
  @Get('status')
  String getStatus() {
    return 'All systems operational';
  }
}
```

**Result:** `Controller('api')` + `Get('status')` = `GET /api/status`

:::tip
Path arguments don't need a leading `/` - Revali adds it automatically.
:::

## Path Parameters

Path parameters let you create dynamic routes that accept variable values. They're defined using `:parameterName` syntax in your route paths.

### How Path Parameters Work

Path parameters create **dynamic segments** in your URLs:

- `:id` matches any single segment (e.g., `/users/123`, `/users/abc`)
- `:userId` matches any single segment (e.g., `/users/john-doe`)
- Multiple parameters can be used in the same route

### Basic Path Parameters

```dart
@Controller('users')
class UsersController {
  @Get(':id')
  String getUser(@Param() String id) {
    return 'User ID: $id';
  }
}
```

**Route:** `GET /users/:id`  
**Examples:**

- `/users/123` → `id = "123"`
- `/users/abc` → `id = "abc"`
- `/users/john-doe` → `id = "john-doe"`

### Multiple Path Parameters

```dart
@Controller('shops')
class ShopsController {
  @Get(':shopId/products/:productId')
  String getProduct(
    @Param() String shopId,
    @Param() String productId,
  ) {
    return 'Shop: $shopId, Product: $productId';
  }
}
```

**Route:** `GET /shops/:shopId/products/:productId`  
**Example:** `/shops/abc/products/xyz` → `shopId = "abc"`, `productId = "xyz"`

### Controller-Level Parameters

You can define path parameters at the controller level to share them across all endpoints:

```dart
@Controller('shops/:shopId')
class ShopController {
  @Get('products')
  String getProducts(@Param() String shopId) {
    return 'Products for shop: $shopId';
  }

  @Get('orders')
  String getOrders(@Param() String shopId) {
    return 'Orders for shop: $shopId';
  }
}
```

**Routes:**

- `GET /shops/:shopId/products`
- `GET /shops/:shopId/orders`

### Path Parameter Rules

- **Always strings**: Path parameters are always `String` type
- **Required**: Path parameters are required - missing values cause 404 errors
- **URL encoded**: Values are automatically URL decoded
- **Case sensitive**: `:userId` ≠ `:UserId`

:::tip
Learn more about extracting and converting path parameters in the [Binding documentation](./binding.md#param---path-parameters).
:::

## Custom HTTP Methods

For special cases, you can create custom HTTP methods:

```dart
import 'package:revali_router/revali_router.dart';

final class CustomMethod extends Method {
  const CustomMethod([String? path]) : super('CUSTOM', path: path);
}

// Usage
@Controller('api')
class ApiController {
  @CustomMethod('special')
  String specialEndpoint() {
    return 'Custom method response';
  }
}
```

**Endpoint:** `CUSTOM /api/special`

### Testing with curl

```bash
curl -X CUSTOM http://localhost:8080/api/special
```

**Response:**

```text
Custom method response
```

## Complete Examples

Here are practical examples for each HTTP method:

### GET - Retrieve Data

```dart
@Controller('users')
class UsersController {
  @Get()
  Future<List<User>> getUsers() async {
    return await userService.getAllUsers();
  }

  @Get(':id')
  Future<User> getUser(@Param() String id) async {
    return await userService.getUserById(id);
  }
}
```

**Endpoints:**

- `GET /users` - Get all users
- `GET /users/:id` - Get specific user

### POST - Create Data

```dart
@Controller('users')
class UsersController {
  @Post()
  Future<User> createUser(@Body() CreateUserRequest request) async {
    return await userService.createUser(request);
  }
}
```

**Endpoint:** `POST /users` - Create new user

### PUT - Replace Entire Resource

```dart
@Controller('users')
class UsersController {
  @Put(':id')
  Future<User> updateUser(
    @Param() String id,
    @Body() UpdateUserRequest request,
  ) async {
    return await userService.replaceUser(id, request);
  }
}
```

**Endpoint:** `PUT /users/:id` - Replace entire user

### PATCH - Partial Update

```dart
@Controller('users')
class UsersController {
  @Patch(':id')
  Future<User> patchUser(
    @Param() String id,
    @Body() PatchUserRequest request,
  ) async {
    return await userService.partialUpdateUser(id, request);
  }
}
```

**Endpoint:** `PATCH /users/:id` - Update specific fields

### DELETE - Remove Data

```dart
@Controller('users')
class UsersController {
  @Delete(':id')
  Future<void> deleteUser(@Param() String id) async {
    await userService.deleteUser(id);
  }
}
```

**Endpoint:** `DELETE /users/:id` - Delete user

### SSE - Server-Sent Events

```dart
@Controller('notifications')
class NotificationsController {
  @SSE('live')
  Stream<String> liveNotifications() async* {
    while (true) {
      yield 'Notification: ${DateTime.now()}';
      await Future.delayed(Duration(seconds: 1));
    }
  }
}
```

**Endpoint:** `GET /notifications/live` - Stream live notifications

### WebSocket - Bidirectional Communication

```dart
@Controller('chat')
class ChatController {
  @WebSocket('room/:roomId')
  Stream<String> chatRoom(@Param() String roomId) async* {
    // Handle WebSocket connection
    yield 'Connected to room: $roomId';
  }
}
```

**Endpoint:** `WebSocket /chat/room/:roomId` - Real-time chat

## What's Next?

Now that you understand HTTP methods, explore these related topics:

1. **[Binding](./binding.md)** - Learn how to extract data from requests
2. **[Pipes](./pipes.md)** - Transform and validate request data
3. **[Controllers](./controllers.md)** - Organize your endpoints effectively

Ready to learn about data binding? Let's explore how to extract data from requests!
