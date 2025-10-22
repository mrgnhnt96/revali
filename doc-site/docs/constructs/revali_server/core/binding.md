---
title: Binding
description: Extract data from requests and inject dependencies
sidebar_position: 2
---

# Data Binding

Binding is how you extract data from HTTP requests and inject dependencies into your endpoint methods. Instead of manually parsing request objects, Revali's binding system automatically extracts and converts data for you.

## What Is Data Binding?

Think of binding as **automatic data extraction**:

- **Path parameters** (`/users/:id`) → `@Param() String id`
- **Query strings** (`?name=john&age=25`) → `@Query() String name`
- **Request headers** (`Authorization: Bearer token`) → `@Header('Authorization') String auth`
- **Request body** (`{"name": "John"}`) → `@Body() User user`
- **Dependencies** (services, repositories) → `@Dep() UserService service`

## Available Binding Annotations

| Annotation  | Purpose                   | Where to Use            | Example                         |
| ----------- | ------------------------- | ----------------------- | ------------------------------- |
| `@Param()`  | Extract path parameters   | Endpoints only          | `@Param() String id`            |
| `@Query()`  | Extract query parameters  | Endpoints only          | `@Query() String? search`       |
| `@Header()` | Extract headers           | Endpoints only          | `@Header() String auth`         |
| `@Body()`   | Extract request body      | Endpoints only          | `@Body() User user`             |
| `@Dep()`    | Inject dependencies       | Endpoints & Controllers | `@Dep() UserService service`    |
| `@Data()`   | Extract from Data Handler | Endpoints & Controllers | `@Data() User currentUser`      |
| `@Bind`     | Custom binding            | Endpoints & Controllers | `@CustomBind() CustomType data` |

:::important
You can only use **one binding annotation per parameter**.
:::

:::info
Some types don't need binding annotations - they're [automatically detected](./implied_binding.md).
:::

## `@Param()` - Path Parameters

Extract values from URL path segments like `/users/:id` or `/shops/:shopId/products/:productId`.

:::info
Path parameters are defined in your route paths using `:parameterName` syntax. Learn more about [creating path parameters in HTTP methods](./methods.md#path-parameters).
:::

### Basic Usage

```dart
@Controller('users')
class UsersController {
  @Get(':id')
  String getUser(@Param() String id) {
    return 'User ID: $id';
  }
}
```

**Request:** `GET /users/123`  
**Result:** `id = "123"`

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

**Request:** `GET /shops/abc/products/xyz`  
**Result:** `shopId = "abc"`, `productId = "xyz"`

### Controller-Level Parameters

```dart
@Controller('shops/:shopId')
class ShopController {
  @Get('products')
  String getProducts(@Param() String shopId) {
    return 'Products for shop: $shopId';
  }
}
```

**Request:** `GET /shops/abc/products`  
**Result:** `shopId = "abc"`

### Custom Parameter Names

When the parameter name doesn't match the path segment:

```dart
@Get(':userId')
String getUser(@Param('userId') String id) {
  return 'User ID: $id';
}
```

### Path Parameter Characteristics

- **Always strings**: Path parameters are always `String` type
- **Required**: Missing path parameters cause 404 errors
- **URL decoded**: Values are automatically URL decoded
- **Case sensitive**: Parameter names are case sensitive

:::caution
Path parameters are always `String` type. Use [pipes](./pipes.md) to convert to other types.
:::

## `@Query()` - Query Parameters

Extract values from URL query strings like `?name=john&age=25&tags=dart,flutter`.

### Basic Query Usage

```dart
@Controller('users')
class UsersController {
  @Get()
  String searchUsers(@Query() String? search) {
    return search != null ? 'Searching for: $search' : 'No search term';
  }
}
```

**Request:** `GET /users?search=john`  
**Result:** `search = "john"`

**Request:** `GET /users`  
**Result:** `search = null`

### Multiple Query Parameters

```dart
@Controller('products')
class ProductsController {
  @Get()
  String getProducts(
    @Query() String? category,
    @Query() int? minPrice,
    @Query() int? maxPrice,
  ) {
    return 'Category: $category, Price: $minPrice-$maxPrice';
  }
}
```

**Request:** `GET /products?category=electronics&minPrice=100&maxPrice=500`  
**Result:** `category = "electronics"`, `minPrice = "100"`, `maxPrice = "500"`

### Multiple Values

When a query parameter appears multiple times:

```dart
@Controller('products')
class ProductsController {
  @Get()
  String getProducts(@Query.all() List<String> tags) {
    return 'Tags: ${tags.join(", ")}';
  }
}
```

**Request:** `GET /products?tags=dart&tags=flutter&tags=web`  
**Result:** `tags = ["dart", "flutter", "web"]`

:::warning
With `@Query()` (without `.all()`), if multiple values exist for the same key, only the last value is used:

`?tags=dart&tags=flutter` → `tags = "flutter"`
:::

### Custom Query Names

```dart
@Get()
String search(@Query('q') String? query) {
  return 'Query: $query';
}
```

**Request:** `GET /search?q=revali`  
**Result:** `query = "revali"`

:::caution
Query parameters are always `String` type. Use [pipes](./pipes.md) to convert to other types.
:::

## `@Header()` - Request Headers

Extract values from HTTP request headers like `Authorization: Bearer token` or `Content-Type: application/json`.

### Basic Header Usage

```dart
@Controller('auth')
class AuthController {
  @Get('profile')
  String getProfile(@Header('Authorization') String? auth) {
    return auth != null ? 'Token: $auth' : 'No authorization';
  }
}
```

**Request:** `GET /auth/profile` with `Authorization: Bearer abc123`  
**Result:** `auth = "Bearer abc123"`

### Common Headers

```dart
@Controller('api')
class ApiController {
  @Post('data')
  String processData(
    @Header('Content-Type') String? contentType,
    @Header('User-Agent') String? userAgent,
  ) {
    return 'Content-Type: $contentType, User-Agent: $userAgent';
  }
}
```

### Multiple Header Values

When a header appears multiple times:

```dart
@Controller('api')
class ApiController {
  @Get()
  String getHeaders(@Header.all('Accept') List<String> accept) {
    return 'Accept headers: ${accept.join(", ")}';
  }
}
```

**Request:** `GET /api` with `Accept: application/json` and `Accept: text/html`  
**Result:** `accept = ["application/json", "text/html"]`

:::warning
Without `@Header.all()`, multiple values are joined with commas: `Accept: json, html` → `accept = "json, html"`
:::

:::caution
Header values are always `String` type. Use [pipes](./pipes.md) to convert to other types.
:::

## `@Body()` - Request Body

Extract data from the HTTP request body, typically JSON data from POST/PUT requests.

### Basic Body Usage

```dart
@Controller('users')
class UsersController {
  @Post()
  String createUser(@Body() Map<String, dynamic> body) {
    return 'Received: $body';
  }
}
```

**Request:** `POST /users` with `{"name": "John", "email": "john@example.com"}`  
**Result:** `body = {"name": "John", "email": "john@example.com"}`

### Typed Objects

```dart
class CreateUserRequest {
  final String name;
  final String email;

  CreateUserRequest({required this.name, required this.email});

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) {
    return CreateUserRequest(
      name: json['name'],
      email: json['email'],
    );
  }
}

@Controller('users')
class UsersController {
  @Post()
  String createUser(@Body() CreateUserRequest request) {
    return 'Creating user: ${request.name} (${request.email})';
  }
}
```

**Request:** `POST /users` with `{"name": "John", "email": "john@example.com"}`  
**Result:** `request = CreateUserRequest(name: "John", email: "john@example.com")`

### Specific Fields

Extract only specific fields from the request body:

```dart
@Controller('users')
class UsersController {
  @Post()
  String createUser(@Body(['data', 'email']) String email) {
    return 'Email: $email';
  }
}
```

**Request:** `POST /users` with:

```json
{
  "data": {
    "email": "john@example.com",
    "password": "secret123"
  }
}
```

**Result:** `email = "john@example.com"` (password is ignored)

:::warning
If the specified keys don't exist in the body, a runtime error occurs unless the parameter is nullable.
:::

:::tip
Revali automatically detects `fromJson` constructors for type conversion!
:::

## `@Dep()` - Dependency Injection

Inject services, repositories, and other dependencies into your endpoints and controllers.

### Controller Constructor (Recommended)

```dart
@Controller('users')
class UsersController {
  const UsersController(
    @Dep() this._userService,
    @Dep() this._logger,
  );

  final UserService _userService;
  final Logger _logger;

  @Get()
  String getUsers() {
    _logger.info('Fetching users');
    return _userService.getAllUsers().toString();
  }
}
```

### Endpoint Parameters

```dart
@Controller('users')
class UsersController {
  @Get(':id')
  String getUser(
    @Param() String id,
    @Dep() UserService userService,
  ) {
    return userService.getUserById(id).toString();
  }
}
```

:::tip
Learn how to [configure dependencies](../../../revali/app-configuration/configure-dependencies.md).
:::

:::warning
Missing dependencies cause runtime errors. Controllers are validated at startup, so issues are caught early.
:::

## `@Data()` - Data Handler

Extract values from the Data Handler, which stores data shared between components during a request.

### Basic Data Usage

```dart
@Controller('users')
class UsersController {
  @Get('profile')
  String getProfile(@Data() User currentUser) {
    return 'Profile for: ${currentUser.name}';
  }
}
```

### Optional Data

```dart
@Controller('users')
class UsersController {
  @Get('settings')
  String getSettings(@Data() UserSettings? settings) {
    return settings != null
      ? 'Settings: $settings'
      : 'No settings found';
  }
}
```

:::warning
Missing data causes runtime errors unless the parameter is nullable.
:::

:::tip
The [Data Handler](../context/core/data_handler.md) is useful for sharing data between middleware, guards, and endpoints.
:::

## Custom Binding

Create custom binding annotations for special cases like accessing the full request object or implementing complex data extraction logic.

### Creating Custom Bindings

```dart title="lib/bindings/current_user_binding.dart"
import 'package:revali_router/revali_router.dart';

class CurrentUserBinding extends Bind<User> {
  const CurrentUserBinding();

  @override
  User bind(BindContext context) {
    // Extract user from JWT token in Authorization header
    final authHeader = context.request.headers['Authorization'];
    final token = authHeader?.replaceFirst('Bearer ', '');

    if (token == null) {
      throw UnauthorizedException('No token provided');
    }

    return _decodeJwtToken(token);
  }

  User _decodeJwtToken(String token) {
    // JWT decoding logic here
    return User(id: '123', name: 'John Doe');
  }
}
```

### Using Custom Bindings

```dart
@Controller('users')
class UsersController {
  @Get('profile')
  String getProfile(@CurrentUserBinding() User currentUser) {
    return 'Hello, ${currentUser.name}!';
  }
}
```

### Dynamic Bindings

For bindings that need runtime arguments (e.g. `CurrentUserBinding(service: UserService())`):

```dart
@Controller('users')
class UsersController {
  @Get('profile')
  String getProfile(@Binds(CurrentUserBinding) User currentUser) {
    return 'Hello, ${currentUser.name}!';
  }
}
```

:::important
Custom binding constructors must be `const` to work as annotations.
:::

## Automatic Type Conversion

Revali automatically converts data types when possible, making your code cleaner and more type-safe.

### `fromJson` Detection

When your class has a `fromJson` constructor, Revali uses it automatically:

```dart
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      age: json['age'] as int,
    );
  }
}

@Controller('users')
class UsersController {
  @Post()
  String createUser(@Body() User user) {
    return 'Created user: ${user.name} (age: ${user.age})';
  }
}
```

**Request:** `POST /users` with `{"name": "John", "age": 25}`  
**Result:** `user = User(name: "John", age: 25)`

:::important
The `fromJson` constructor must accept exactly one parameter.
:::

### Using Pipes for Complex Conversion

For more complex transformations, use [pipes](./pipes.md):

```dart
@Controller('users')
class UsersController {
  @Get(':id')
  User getUser(@Param.pipe(UserPipe) User user) {
    return user;
  }
}
```

## Best Practices

### Use the Right Binding

```dart
// ✅ Good - path parameter
@Get(':id')
String getUser(@Param() String id) => userService.getUser(id);

// ✅ Good - query parameter
@Get()
String searchUsers(@Query() String? search) => userService.search(search);

// ✅ Good - request body
@Post()
String createUser(@Body() CreateUserRequest request) => userService.create(request);

// ✅ Good - dependency injection
@Get()
String getUsers(@Dep() UserService userService) => userService.getAll();
```

### Keep Parameters Focused

```dart
// ✅ Good - focused parameters
@Post()
String createUser(
  @Body() CreateUserRequest request,
  @Dep() UserService userService,
) {
  return userService.create(request);
}

// ❌ Avoid - too many parameters
@Post()
String createUser(
  @Body() CreateUserRequest request,
  @Dep() UserService userService,
  @Dep() EmailService emailService,
  @Dep() NotificationService notificationService,
  @Dep() AuditService auditService,
  @Dep() CacheService cacheService,
) {
  // Too many dependencies in endpoint
}
```

### Handle Optional Data

```dart
// ✅ Good - nullable for optional data
@Get()
String searchUsers(
  @Query() String? search,
  @Query() int? limit,
  @Query() int? offset,
) {
  return userService.search(search, limit: limit, offset: offset);
}
```

## What's Next?

Now that you understand data binding, explore these related topics:

1. **[Pipes](./pipes.md)** - Transform and validate bound data
2. **[Implied Binding](./implied_binding.md)** - Types that don't need annotations
3. **[HTTP Methods](./methods.md)** - Define endpoint behavior
4. **[Controllers](./controllers.md)** - Organize your endpoints

Ready to learn about data transformation? Let's explore pipes!
