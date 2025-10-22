---
sidebar_position: 5
description: Configure your server using environment variables
---

# Environment Variables

Environment variables are for configuring your Revali application across different environments. They allow you to externalize configuration, manage secrets securely, and adapt your application behavior without code changes.

## What are Environment Variables?

Environment variables provide:

- **Configuration Management**: Externalize settings from your code
- **Security**: Keep sensitive data like API keys and passwords out of source control
- **Environment Flexibility**: Different settings for development, staging, and production
- **Deployment Simplicity**: Easy configuration changes without code deployment

## Setting Environment Variables

### Using .env Files

The most convenient way to manage environment variables is with `.env` files:

```env title=".env"
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp_dev
DB_USER=postgres
DB_PASSWORD=secret123

# API Keys
STRIPE_API_KEY=sk_test_123456789
SENDGRID_API_KEY=SG.123456789

# Application Settings
APP_ENV=development
LOG_LEVEL=debug
API_RATE_LIMIT=1000
```

:::danger
**Never commit `.env` files to source control!** Add them to your `.gitignore` file.
:::

:::info
You can name your environment file anything (e.g., `.env.local`, `.env.production`), but `.env` is the most common convention.
:::

#### Using .env Files with Revali

```bash
# Development with .env file
dart run revali dev --dart-define-from-file=.env

# Production with .env file
dart run revali build --dart-define-from-file=.env.production
```

### Command Line Variables

Set environment variables directly from the command line:

```bash
# Single variable
dart run revali dev --dart-define=DB_HOST=localhost

# Multiple variables
dart run revali dev --dart-define=DB_HOST=localhost --dart-define=DB_PORT=5432

# Build with variables
dart run revali build --dart-define=APP_ENV=production --dart-define=LOG_LEVEL=info
```

### System Environment Variables

Use system environment variables:

```bash
# Set system environment variables
export DB_HOST=localhost
export DB_PORT=5432
export STRIPE_API_KEY=sk_test_123456789

# Run Revali (will automatically pick up system variables)
dart run revali dev
```

## Accessing Environment Variables

There are two different ways to access environment variables in Dart, depending on how they were set:

### Variables Set with `.env` or `--dart-define`

Variables set using `.env` files or `--dart-define` flags are accessed using Dart's compile-time constants:

```dart
// Accessing variables set with --dart-define or .env files
const String dbHost = String.fromEnvironment('DB_HOST', defaultValue: 'localhost');
const int dbPort = int.fromEnvironment('DB_PORT', defaultValue: 5432);
const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: false);
const String apiKey = String.fromEnvironment('STRIPE_API_KEY', defaultValue: '');
```

### System Environment Variables

Variables set as system environment variables are accessed using `Platform.environment`:

```dart
import 'dart:io';

// Accessing system environment variables
final String dbHost = Platform.environment['DB_HOST'] ?? 'localhost';
final int dbPort = int.parse(Platform.environment['DB_PORT'] ?? '5432');
final String apiKey = Platform.environment['STRIPE_API_KEY'] ?? '';
```

### Key Differences

| Method                   | Access Pattern             | When Available | Use Case                 |
| ------------------------ | -------------------------- | -------------- | ------------------------ |
| `.env` / `--dart-define` | `String.fromEnvironment()` | Compile time   | Build-time configuration |
| System Environment       | `Platform.environment`     | Runtime        | Runtime configuration    |

### In Your App Configuration

Here's how to use both methods in your `AppConfig`:

```dart title="routes/main_app.dart"
import 'dart:io';

@App()
class MainApp extends AppConfig {
  MainApp() : super(
    // Use compile-time constants for build configuration
    host: const String.fromEnvironment('HOST', defaultValue: 'localhost'),
    port: const int.fromEnvironment('PORT', defaultValue: 8080),
    prefix: const String.fromEnvironment('API_PREFIX', defaultValue: '/api'),
  );

  @override
  Future<void> configureDependencies(DI di) async {
    // Use runtime environment variables for dynamic configuration
    di.registerLazySingleton<DatabaseConnection>(
      () => DatabaseConnection(
        host: Platform.environment['DB_HOST'] ?? 'localhost',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME'] ?? 'myapp',
        username: Platform.environment['DB_USER'] ?? 'postgres',
        password: Platform.environment['DB_PASSWORD'] ?? '',
      ),
    );

    // Mix both approaches as needed
    di.registerLazySingleton<StripeService>(
      () => StripeService(
        apiKey: Platform.environment['STRIPE_API_KEY'] ??
                const String.fromEnvironment('STRIPE_API_KEY', defaultValue: ''),
      ),
    );
  }
}
```

### Best Practices for Variable Access

#### Use Compile-Time Constants For

- **Build Configuration**: Host, port, API prefix
- **Feature Flags**: Enable/disable features at build time
- **Static Values**: Values that don't change at runtime

```dart
// Good for compile-time configuration
const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'MyApp');
const bool enableDebugMode = bool.fromEnvironment('DEBUG', defaultValue: false);
const int maxConnections = int.fromEnvironment('MAX_CONNECTIONS', defaultValue: 100);
```

#### Use Runtime Environment For

- **Secrets**: API keys, passwords, tokens
- **Database Configuration**: Connection strings, credentials
- **Dynamic Values**: Values that might change without rebuilding

```dart
// Good for runtime configuration
final String dbPassword = Platform.environment['DB_PASSWORD'] ?? '';
final String jwtSecret = Platform.environment['JWT_SECRET'] ?? '';
final String redisUrl = Platform.environment['REDIS_URL'] ?? 'redis://localhost:6379';
```

## Environment Variable Best Practices

### 🔒 **Security**

- **Never Commit Secrets**: Keep `.env` files out of source control
- **Use Different Keys**: Use different API keys for different environments
- **Rotate Keys Regularly**: Regularly rotate API keys and passwords
- **Validate Required Variables**: Check for required variables at startup

### 🏗️ **Organization**

- **Consistent Naming**: Use consistent naming conventions (e.g., `DB_HOST`, `API_KEY`)
- **Group Related Variables**: Group related variables with prefixes
- **Document Variables**: Document all environment variables
- **Provide Defaults**: Provide sensible defaults for non-sensitive variables

### 🚀 **Deployment**

- **Environment Parity**: Keep environment variables consistent across environments
- **Validation**: Validate environment variables at startup
- **Fallbacks**: Provide fallback values for optional variables
- **Monitoring**: Monitor environment variable usage

## Tools and Utilities

### pnv Package

The [`pnv`](https://pub.dev/packages/pnv) package converts `.env` files to `--dart-define` flags:

```bash
# Install pnv
dart pub global activate pnv

# Convert .env to dart-define flags
dart run revali dev $(pnv to-dart-define .env)
```

## Troubleshooting

### Common Issues

**Variables Not Found:**

- Check variable names for typos
- Ensure variables are set before running Revali
- Verify the `.env` file is in the correct location

**Type Conversion Errors:**

- Ensure numeric variables contain valid numbers
- Use proper parsing for integers and booleans
- Provide fallback values for type conversion

**Security Issues:**

- Never log sensitive environment variables
- Use different keys for different environments
- Regularly rotate API keys and passwords

## Next Steps

- **[Flavors](/revali/app-configuration/flavors)**: Create environment-specific configurations
- **[Default Responses](/revali/app-configuration/default-responses)**: Customize default server responses
