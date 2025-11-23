---
description: Store and retrieve metadata associated with endpoints and requests
---

# Meta

> Access via: `context.meta`

Metadata allows you to attach custom information to endpoints and access it during request processing. This is useful for storing configuration, annotations, or any data that needs to be shared between different parts of your application.

## Creating Metadata Classes

To create metadata, implement the `MetaData` interface:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

class Public implements MetaData {
  const Public();
}

class Role implements MetaData {
  const Role(this.name);

  final String name;
}
```

## Basic Operations

### Annotating with Metadata

Metadata is stored by annotating controllers and methods:

```dart
@Controller('api')
class ApiController {
  @Public()
  @Get('health')
  String healthCheck() {
    return 'OK';
  }

  @Role('admin')
  @Get('admin-data')
  String adminData() {
    return 'Admin only data';
  }
}
```

### Retrieving Metadata

Get metadata using `get()` - returns a list of all instances:

```dart
// Get all instances of a type
List<Role> roles = context.meta.get<Role>();
// Returns: [Role('admin')] for the admin-data endpoint
```

### Checking for Metadata

Check if metadata exists using `has()`:

```dart
if (context.meta.has<Public>()) {
  // This endpoint is public
}

if (context.meta.has<Role>()) {
  // This endpoint has role metadata
}
```

## Direct vs Inherited Metadata

The `MetaScope` provides access to both direct and inherited metadata:

```dart
@Controller('api')
class ApiController {
  @Role('admin')  // This will be inherited by all methods
  @Get('users')
  String getUsers() {
    // Direct metadata - attached to this specific method
    List<Role> directRoles = context.meta.direct.get<Role>();

    // Inherited metadata - from parent controller
    List<Role> inheritedRoles = context.meta.inherited.get<Role>();

    return 'Users data';
  }
}
```

## Real-World Examples

### 1. Public Endpoint Marking

Mark endpoints as public to bypass authentication:

```dart
class Public implements MetaData {
  const Public();
}

@Controller('api')
class ApiController {
  @Public()
  @Get('health')
  String healthCheck() {
    return 'OK';
  }
}

// In your auth guard
class AuthGuard implements Guard {
  Future<GuardResult> protect(GuardContext context) async {
    if (context.meta.has<Public>()) {
      return const GuardResult.pass();
    }

    // Check authentication...
  }
}
```

### 2. Route Configuration

Store route-specific configuration:

```dart
class CodeName implements MetaData {
  const CodeName(this.name);

  final String name;
}

@Controller('api')
class ApiController {

  @CodeName('API-1234')
  @Get('data')
  String getData(Meta meta) {
    final codeName = meta.get<CodeName>()?.single;
    return codeName?.name ?? 'No code name';
  }
}
```

## What's Next?

- Learn about [data sharing](./data-sharing.md) for storing runtime data
- Explore [reflection](./reflect.md) for accessing metadata on types
- See [lifecycle components](../lifecycle-components/components.md) for using metadata in guards and interceptors
