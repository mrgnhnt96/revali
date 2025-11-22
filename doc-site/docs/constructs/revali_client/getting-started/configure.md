---
title: Configure
description: Learn how to configure Revali Client
sidebar_position: 1
---

# Configuration

Revali Client provides flexible configuration options to customize your generated client code. All configuration is done through the `revali.yaml` file in your project root.

## Basic Configuration

To enable Revali Client, add it to your `revali.yaml` constructs list:

```yaml title="revali.yaml"
constructs:
  - name: revali_client
```

This minimal configuration will use all default values. For most projects, you'll want to customize at least a few options:

```yaml title="revali.yaml"
constructs:
  - name: revali_client
    options:
      package_name: client
      server_name: Server
      scheme: http
```

---

## Configuration Options

### `package_name`

**Type**: `string`  
**Default**: `client`

Customizes the name of the generated package. This affects:

- The import path: `package:{package_name}/client.dart`
- The directory name: `.revali/{package_name}/`
- The package name in the generated `pubspec.yaml`

#### Example

```yaml title="revali.yaml"
constructs:
  - name: revali_client
    options:
      package_name: my_api_client
```

**Generated import:**

```dart
import 'package:my_api_client/client.dart';
import 'package:my_api_client/interfaces.dart';
```

**Generated directory:**

```text
.revali/
└── my_api_client/
    ├── lib/
    └── pubspec.yaml
```

:::tip
**Naming Convention**: Use snake_case for package names to follow Dart conventions.
:::

---

### `server_name`

**Type**: `string`  
**Default**: `Server`

Customizes the name of the main client class. This is useful when you want a more descriptive name or when integrating with existing code.

#### Example

```yaml title="revali.yaml"
constructs:
  - name: revali_client
    options:
      server_name: ApiClient
```

**Generated code:**

```dart
// Instead of:
final server = Server();

// You get:
final server = ApiClient();
```

:::important
**Naming Rules**:

- Must follow Dart class naming conventions (PascalCase)
- Cannot contain spaces or special characters
- Should be a valid Dart identifier

:::

#### Common Use Cases

```yaml
# For a backend API
server_name: BackendClient

# For a microservice
server_name: UserServiceClient

# For a third-party integration
server_name: StripeApiClient
```

---

### `scheme`

**Type**: `string`  
**Default**: `http`

Sets the URL scheme (protocol) for all API requests. This is combined with your server's host and port configuration to build the base URL.

#### Example

```yaml title="revali.yaml"
constructs:
  - name: revali_client
    options:
      scheme: https
```

**How it works:**

The scheme is combined with your app configuration:

```dart
// If your AppConfig has:
// - host: 'api.example.com'
// - port: '443'
// - scheme: 'https'

// The client constructs URLs like:
// https://api.example.com:443/api/users
```

#### Common Values

| Scheme  | Use Case                       |
| ------- | ------------------------------ |
| `http`  | Local development, testing     |
| `https` | Production, secure connections |

:::tip
**Development vs Production**: Use `http` for local development and `https` for production deployments. You can use different `revali.yaml` configurations or environment-based builds.
:::

---

### `integrations`

**Type**: `object`  
**Default**: `{}`

Enables integration with popular Dart packages and frameworks. Currently supported integrations:

#### `get_it`

Automatically generates dependency injection registration code for the [get_it](https://pub.dev/packages/get_it) package.

```yaml title="revali.yaml"
constructs:
  - name: revali_client
    options:
      integrations:
        get_it: true
```

**What it does:**

- Adds `get_it` to the generated package dependencies
- Creates a `register()` extension method for easy registration
- Registers all data sources with the service locator

**Generated code:**

```dart
import 'package:client/client.dart';
import 'package:get_it/get_it.dart';

void main() {
  final getIt = GetIt.instance;

  // Register all services at once
  getIt.registerServer();

  // Use registered services
  final users = getIt<UserDataSource>();
  final posts = getIt<PostDataSource>();
}
```

:::info
Learn more about the [get_it integration](/constructs/revali_client/integrations/get_it).
:::

---

## Excluding Controllers and Methods

Sometimes you may want to prevent certain controllers or endpoints from being generated in the client code. This is useful for:

- Admin-only endpoints that shouldn't be exposed to clients
- Internal APIs used only by the server
- Deprecated endpoints being phased out
- Testing or debugging endpoints

### Using `@ExcludeFromClient`

Import the annotation from `revali_client`:

```dart
import 'package:revali_client/revali_client.dart';
```

### Excluding an Entire Controller

Prevents all endpoints in a controller from being generated:

```dart
import 'package:revali_client/revali_client.dart';
import 'package:revali_router/revali_router.dart';

@ExcludeFromClient()
@Controller('admin')
class AdminController {
  @Get('users')
  Future<List<User>> getAllUsers() async {
    // This endpoint won't be in the generated client
  }

  @Delete('user/:id')
  Future<void> deleteUser(@Param('id') String id) async {
    // This won't be generated either
  }
}
```

### Excluding Specific Methods

Exclude individual endpoints while keeping the rest of the controller:

```dart
import 'package:revali_client/revali_client.dart';
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  @Get()
  Future<List<User>> getAll() async {
    // ✅ Generated in client
  }

  @ExcludeFromClient()
  @Get('internal/stats')
  Future<UserStats> getInternalStats() async {
    // ❌ Not generated in client
  }

  @Post()
  Future<User> create(@Body() User user) async {
    // ✅ Generated in client
  }
}
```

---

## Complete Configuration Reference

Here's a complete configuration example with all available options:

```yaml title="revali.yaml"
constructs:
  - name: revali_client
    options:
      # Package configuration
      package_name: my_client # Default: client
      server_name: ApiClient # Default: Server

      # Network configuration
      scheme: https # Default: http

      # Integrations
      integrations:
        get_it: true # Default: false
```

---

## Validating Your Configuration

After updating your `revali.yaml`, validate it by running:

```bash
revali dev
```

Or for a production build:

```bash
revali build
```

---

## What's Next?

Now that you've configured Revali Client, you're ready to:

- **[Understand Generated Code](/constructs/revali_client/generated-code)** - Learn about the structure of generated files
- **[Use HTTP Interceptors](/constructs/revali_client/getting-started/http-interceptors)** - Add request/response handling
- **[Set Up Storage](/constructs/revali_client/getting-started/storage)** - Manage cookies and sessions
- **[Integrate with get_it](/constructs/revali_client/integrations/get_it)** - Set up dependency injection

Ready to dive deeper? Learn about the [generated code structure](/constructs/revali_client/generated-code)!
