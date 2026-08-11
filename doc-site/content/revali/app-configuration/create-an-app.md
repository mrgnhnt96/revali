---
title: Create an App
description: Create an app and configure host & port
---

Creating an app configuration is the first step in setting up your Revali application. This guide will walk you through creating your first app configuration.

<Callout type="tip">

You can quickly create an app configuration using the CLI command:

```bash
dart run revali create app
```

</Callout>

## Project Structure

First, let's understand where to place your app configuration:

```tree
your_project/
├── lib/
│   └── <your-dart-files>
├── routes/
│   └── my_app.dart          # Your app configuration
├── pubspec.yaml
└── revali.yaml
```

<Callout type="important">

**File Naming Requirements:**

- App files must end with `_app.dart` or `.app.dart`
- Files must be placed in the `routes/` directory
- You can nest app files in subdirectories within `routes/`

</Callout>

## Step 1: Create the App File

Create a new file in your `routes/` directory. Let's call it `main_app.dart`:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);
}
```

</CodeFile>

## Step 2: Understanding the Components

### The `@App()` Annotation

The `@App()` annotation tells Revali that this class is an application configuration. This annotation is required for Revali to recognize and process your app.

### The `AppConfig` Base Class

`AppConfig` is the base class that provides the foundation for your application configuration. It handles:

- Server initialization
- Dependency injection setup
- Middleware configuration
- Request/response processing

### Constructor Parameters

The `AppConfig` constructor requires two essential parameters:

- **`host`**: The hostname where your server will listen (e.g., `'localhost'`, `'0.0.0.0'`)
- **`port`**: The port number for your server (e.g., `8080`, `3000`)

## Step 3: Basic Configuration Options

### Host Configuration

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  // Listen on localhost only
  const MainApp() : super(host: 'localhost', port: 8080);
}
```

</CodeFile>

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  // Listen on all network interfaces
  const MainApp() : super(host: '0.0.0.0', port: 8080);
}
```

</CodeFile>

### Port Configuration

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  // Development port
  const MainApp() : super(host: 'localhost', port: 3000);
}
```

</CodeFile>

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  // Production port
  const MainApp() : super(host: 'localhost', port: 80);
}
```

</CodeFile>

## Step 4: Advanced Configuration

### Global Prefix

Add a global prefix to all your API routes:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(
    host: 'localhost',
    port: 8080,
    prefix: '/api/v1',  // All routes will be prefixed with /api/v1
  );
}
```

</CodeFile>

### Trusted Proxy

When your server sits behind a reverse proxy or load balancer, override `trustedProxy` so `request.ip` and `@Ip()` resolve the real client from proxy headers instead of the proxy's TCP address:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  TrustedProxy get trustedProxy => const TrustedProxy(
    headers: ['X-Forwarded-For'],
  );
}
```

</CodeFile>

Leave the default (`const TrustedProxy()`) when clients connect directly — proxy headers are ignored in that case.

See [Client IP](/constructs/revali_server/request/client-ip) for `useLeftmostIp`, header precedence, and security guidance.

### Complete Example

Here's a complete app configuration with all common options:

<CodeFile name="routes/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(
    host: 'localhost',
    port: 8080,
    prefix: '/api',
  );

  @override
  Future<void> configureDependencies(DI di) async {
    // Register your dependencies here
    // We'll cover this in the next guide
  }
}
```

</CodeFile>

## Step 5: Running Your App

Once you've created your app configuration, you can start your server:

```bash
dart run revali dev
```

Your server will be available at the configured host and port (e.g., `http://localhost:8080/api/`).

## Multiple App Configurations

You can create multiple app configurations for different purposes:

<CodeFile name="routes/api_app.dart">

```dart
@App()
final class ApiApp extends AppConfig {
  const ApiApp() : super(
    host: 'localhost',
    port: 8080,
    prefix: '/api',
  );
}
```

</CodeFile>

<CodeFile name="routes/admin_app.dart">

```dart
@App()
final class AdminApp extends AppConfig {
  const AdminApp() : super(
    host: 'localhost',
    port: 8081,
    prefix: '/admin',
  );
}
```

</CodeFile>

## Best Practices

### 📁 **File Organization**

- Use descriptive names: `main_app.dart`, `api_app.dart`, `admin_app.dart`
- Group related apps in subdirectories: `routes/api/main_app.dart`
- Keep app configurations focused and single-purpose

### 🔧 **Configuration Management**

- Use environment variables for host and port in production
- Create separate configurations for different environments
- Document your configuration choices

### 🚀 **Performance**

- Choose appropriate host settings for your deployment
- Use non-privileged ports (>1024) for development
- Consider using `0.0.0.0` for containerized deployments

## Troubleshooting

### Common Issues

**App Not Recognized:**

- Ensure the file ends with `_app.dart` or `.app.dart`
- Verify the file is in the `routes/` directory
- Check that the `@App()` annotation is present

**Port Already in Use:**

- Change the port number in your configuration
- Check if another service is using the port
- Use `lsof -i :8080` to find processes using the port

**Host Binding Issues:**

- Use `localhost` for local development
- Use `0.0.0.0` for network access
- Check firewall settings

## Next Steps

- **[Configure Dependencies](/revali/app-configuration/configure-dependencies)**: Set up dependency injection
- **[Environment Variables](/revali/app-configuration/env-vars)**: Handle configuration across environments
- **[Flavors](/revali/app-configuration/flavors)**: Create environment-specific configurations
