---
description: Access metadata on types and their properties using reflection
---

# Reflect

> Access via: `context.reflect`

The `Reflect` object provides runtime reflection capabilities to analyze metadata on types and their properties. This is useful for building generic components that need to inspect and process data based on metadata annotations.

## Basic Operations

### Getting a Reflector

Get a `Reflector` for a specific type to analyze its properties:

```dart
// Get reflector for a specific type
Reflector? reflector = context.reflect.get<User>();
```

### Analyzing Property Metadata

Use the reflector to access metadata on specific properties:

```dart
// Get metadata for a specific property
Meta? propertyMeta = reflector?.get('password');

// Get all property metadata
Map<String, Meta> allMeta = reflector?.meta ?? {};
```

## Real-World Example: Data Sanitization

Here's how reflection is used to build a generic data sanitizer that removes private fields:

```dart
class Access implements MetaData {
  const Access(this.type);
  final AccessType type;
}

enum AccessType { public, private }

class User {
  const User({required this.name, required this.password});

  final String name;

  @Access(AccessType.private)
  final String password;
}

// Generic sanitizer using reflection
class DataSanitizer implements LifecycleComponent {
  InterceptorPostResult sanitize(Response response, Reflect reflect) {
    final reflector = reflect.get<User>();
    final body = response.body.data;

    if (body case {'data': final Map<String, dynamic> data}) {
      final json = {...data};

      // Iterate through each property in the response
      for (final key in data.keys) {
        final meta = reflector?.get(key);
        final access = meta?.get<Access>();

        // Remove private fields
        if (access?.any((e) => e.type == AccessType.private) ?? false) {
          json.remove(key);
        }
      }

      response.body = {'data': json};
    }
  }
}
```

## Common Use Cases

### 1. Data Sanitization

Remove sensitive fields from API responses based on metadata annotations.

### 2. Validation

Apply validation rules based on property metadata.

## What's Next?

- Learn about [metadata](./meta.md) for creating custom annotations
- Explore [data sharing](./data-sharing.md) for runtime data storage
- See [lifecycle components](../lifecycle-components/components.md) for using reflection in guards and interceptors
