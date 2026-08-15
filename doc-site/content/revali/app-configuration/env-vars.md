---
title: Environment Variables
description: Configure your server using environment variables
---

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

<CodeFile name=".env">

```env
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

</CodeFile>

<Callout type="danger">

**Never commit `.env` files to source control!** Add them to your `.gitignore` file.

</Callout>

<Callout type="info">

You can name your environment file anything (e.g., `.env.local`, `.env.production`), but `.env` is the most common convention.

</Callout>

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

### `Env` — the runtime reader

Revali ships `Env` for reading the process environment. Prefer it over `Platform.environment`: it parses, it validates, and it fails loudly at startup rather than quietly at the first request that needed the value.

```dart
final port = Env.current.integer('PORT', orElse: 8080);
final users = Env.current.uri('USERS_SERVICE_URL');
final apiKey = Env.current.require('STRIPE_API_KEY');
final tracing = Env.current.boolean('ENABLE_TRACING', orElse: false);
```

| Method | Returns | When unset | When invalid |
|---|---|---|---|
| `env['NAME']` | `String?` | `null` | — |
| `env.has('NAME')` | `bool` | `false` | — |
| `env.string('NAME', orElse: …)` | `String` | `orElse` | — |
| `env.require('NAME')` | `String` | **throws** | — |
| `env.integer('NAME', orElse: …)` | `int` | `orElse` | **throws** |
| `env.boolean('NAME', orElse: …)` | `bool` | `orElse` | **throws** |
| `env.uri('NAME', orElse: …)` | `Uri` | `orElse`, or **throws** without one | **throws** |

Two behaviors are worth knowing about, because both exist to catch a specific way deployments go wrong:

- **An empty value counts as unset.** Orchestrators and CI systems routinely inject `""` for a variable nobody configured, and treating that as a real value is how an app ends up connecting to nothing.
- **A value that is present but malformed throws** rather than falling back. Someone set `PORT=eighty` on purpose; listening on `8080` instead is worse than not starting.

`boolean` accepts `true`/`1`/`yes`/`on` and `false`/`0`/`no`/`off`, case-insensitively. Anything else throws — a feature flag set to `"maybe"` should be a deployment error, not a silent no.

<Callout type="tip">

`Env` takes an explicit map, so a test never has to mutate the real process environment:

```dart
final env = Env({'PORT': '9000', 'ENABLE_TRACING': 'true'});
```

</Callout>

### `AppConfig.fromEnv` — host and port from the environment

An app that reads its own address from the environment does not need to be rebuilt to be deployed somewhere else:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  MainApp() : super.fromEnv();
}
```

</CodeFile>

Two of its defaults differ from the ordinary constructor deliberately:

- **Host is `0.0.0.0`, not `localhost`.** A server bound to `localhost` inside a container accepts only connections originating in that same container, so every request from outside is refused — with the process looking perfectly healthy.
- **Port comes from `PORT`.** Cloud Run, Heroku, Render and Fly all assign a port this way and route to it. So do [`revali up`](/revali/cli/up) and [`revali compose`](/revali/cli/compose), which is why a service that hard-codes its port ignores the one it was given.

The variable names and defaults are all overridable:

```dart
MainApp()
    : super.fromEnv(
        hostVariable: 'BIND_HOST',
        portVariable: 'HTTP_PORT',
        defaultPort: 3000,
        prefix: '/api',
      );
```

<Callout type="important">

`fromEnv` is **not** `const` — it reads the process environment, which is only knowable at runtime — so the app class cannot have a `const` constructor either. That is the whole point: a port baked in at compile time is a port the platform running the image cannot change.

</Callout>

### Compile-Time Constants

Variables set with `--dart-define` or `--dart-define-from-file` are baked into the binary and read with Dart's `fromEnvironment` constructors:

```dart
const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'MyApp');
const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: false);
```

These are genuine compile-time constants, so they can be used where a `const` is required — which is also their limitation: changing one means rebuilding.

### Key Differences

| Method                   | Access Pattern             | When Available | Use Case                 |
| ------------------------ | -------------------------- | -------------- | ------------------------ |
| `.env` / `--dart-define` | `String.fromEnvironment()` | Compile time   | Build-time configuration |
| System Environment       | `Env.current`              | Runtime        | Runtime configuration    |

Reach for compile-time constants when the value belongs to the *build*, and `Env` when it belongs to the *deployment*. A container image promoted from staging to production is the same build told different things by its environment, so anything that differs between the two has to be read at runtime.

### In Your App Configuration

Here's how to use both methods in your `AppConfig`:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  // Host and port come from the environment.
  MainApp() : super.fromEnv(prefix: '/api');

  @override
  Future<void> configureDependencies(DI di) async {
    final env = Env.current;

    di.registerLazySingleton<DatabaseConnection>(
      () => DatabaseConnection(
        host: env.string('DB_HOST', orElse: 'localhost'),
        port: env.integer('DB_PORT', orElse: 5432),
        database: env.string('DB_NAME', orElse: 'myapp'),
        username: env.string('DB_USER', orElse: 'postgres'),
        // No sensible default for a password: fail at startup, by name.
        password: env.require('DB_PASSWORD'),
      ),
    );

    di.registerLazySingleton<StripeService>(
      () => StripeService(apiKey: env.require('STRIPE_API_KEY')),
    );
  }
}
```

</CodeFile>

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
final String dbPassword = Env.current.require('DB_PASSWORD');
final String jwtSecret = Env.current.require('JWT_SECRET');
final Uri redisUrl = Env.current.uri('REDIS_URL', orElse: Uri.parse('redis://localhost:6379'));
```

`require` over a `?? ''` fallback: a missing secret should stop the process at startup, naming the variable, rather than reaching the database as an empty password and failing somewhere that does not mention configuration at all.

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
