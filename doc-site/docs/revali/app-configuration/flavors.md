---
sidebar_position: 3
description: Dev, Prod, and everything in between
---

# Flavors

Flavors allow you to create different configurations for different environments (development, staging, production) within the same Revali application. This enables you to manage environment-specific settings, dependencies, and behaviors without duplicating code.

## What are Flavors?

Flavors are named configurations that let you:

- **Environment Separation**: Different settings for dev, staging, and production
- **Configuration Management**: Environment-specific database connections, API keys, and settings
- **Deployment Flexibility**: Easy switching between environments
- **Code Reuse**: Share common configuration while customizing per environment

## Creating Flavors

To create a flavor, specify the flavor name in the `@App()` annotation:

:::caution
**Flavors are case-sensitive.** `'development'` and `'Development'` are different flavors.
:::

### Development Flavor

```dart title="routes/dev_app.dart"
import 'package:revali_annotations/revali_annotations.dart';

@App(flavor: 'development')
class DevApp extends AppConfig {
  const DevApp() : super(
    host: 'localhost',
    port: 8080,
    prefix: '/api',
  );

  @override
  Future<void> configureDependencies(DI di) async {
    // Development-specific dependencies
    di.registerLazySingleton<DatabaseConnection>(
      () => DatabaseConnection(
        host: 'localhost',
        port: 5432,
        database: 'myapp_dev',
      ),
    );

    di.registerLazySingleton<EmailService>(
      () => MockEmailService(), // Use mock for development
    );
  }
}
```

### Production Flavor

```dart title="routes/prod_app.dart"
import 'package:revali_annotations/revali_annotations.dart';

@App(flavor: 'production')
class ProdApp extends AppConfig {
  const ProdApp() : super(
    host: '0.0.0.0',
    port: 80,
    prefix: '/api',
  );

  @override
  Future<void> configureDependencies(DI di) async {
    // Production-specific dependencies
    di.registerLazySingleton<DatabaseConnection>(
      () => DatabaseConnection.fromEnv(), // Use environment variables
    );

    di.registerLazySingleton<EmailService>(
      () => SMTPEmailService.fromEnv(), // Use real email service
    );
  }
}
```

### Staging Flavor

```dart title="routes/staging_app.dart"
import 'package:revali_annotations/revali_annotations.dart';

@App(flavor: 'staging')
class StagingApp extends AppConfig {
  const StagingApp() : super(
    host: '0.0.0.0',
    port: 8080,
    prefix: '/api',
  );

  @override
  Future<void> configureDependencies(DI di) async {
    // Staging-specific dependencies
    di.registerLazySingleton<DatabaseConnection>(
      () => DatabaseConnection(
        host: Platform.environment['DB_HOST'] ?? 'staging-db.example.com',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: 'myapp_staging',
      ),
    );

    di.registerLazySingleton<EmailService>(
      () => SMTPEmailService.fromEnv(),
    );
  }
}
```

## Using Flavors

### Development Server

Run your application with a specific flavor:

```bash
# Development environment
dart run revali dev --flavor=development

# Staging environment
dart run revali dev --flavor=staging

# Production environment
dart run revali dev --flavor=production
```

### Build Process

Build your application for a specific environment:

```bash
# Development build
dart run revali build --flavor=development

# Staging build
dart run revali build --flavor=staging

# Production build
dart run revali build --flavor=production
```

## Troubleshooting Flavors

### Common Issues

**Flavor Not Found:**

- Ensure the flavor name matches exactly (case-sensitive)
- Verify the `@App(flavor: 'name')` annotation is correct

## Next Steps

- **[Environment Variables](/revali/app-configuration/env-vars)**: Learn about environment variable configuration
- **[Default Responses](/revali/app-configuration/default-responses)**: Customize default server responses
