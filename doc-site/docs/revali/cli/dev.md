---
title: revali dev
sidebar_position: 0
description: Start the server and develop your Revali application
---

# The Dev Command

The `revali dev` command is the primary development tool for Revali applications. It starts your development server with hot reload, debugging support, and automatic code generation.

## What Does `revali dev` Do?

When you run `revali dev`, Revali:

1. **Analyzes Your Code**: Scans your `routes/` directory for controllers and app configurations
2. **Generates Server Code**: Creates the necessary server implementation using constructs
3. **Starts the Server**: Launches your API server with the configured host and port
4. **Enables Hot Reload**: Monitors file changes and automatically reloads the server
5. **Provides Debugging**: Starts a Dart VM service for debugging and profiling

## Basic Usage

```bash
dart run revali dev
```

This starts your server with default settings:

- **Host**: `localhost`
- **Port**: `8080`
- **API Prefix**: `/api`
- **Mode**: Debug (with VM service)

## Run Modes

Revali supports three different run modes, each optimized for different scenarios:

### Debug Mode (Default)

Debug mode provides the best development experience with full debugging capabilities:

```bash
dart run revali dev --debug
```

**Features:**

- ✅ Dart VM service enabled
- ✅ Hot reload support
- ✅ Debugger attachment
- ✅ Stack traces in responses
- ✅ Development optimizations

**When to use:**

- Local development
- Debugging issues
- Testing new features

### Release Mode

Release mode optimizes for performance and production-like behavior:

```bash
dart run revali dev --release
```

**Features:**

- ❌ No Dart VM service
- ✅ Performance optimizations
- ✅ Production-like behavior
- ❌ No debugging support
- ✅ Optimized code generation

**When to use:**

- Performance testing
- Production simulation
- Load testing

### Profile Mode

Profile mode balances performance with debugging information:

```bash
dart run revali dev --profile
```

**Features:**

- ❌ No Dart VM service
- ✅ Performance optimizations
- ✅ Stack traces in responses
- ✅ Debug information available
- ✅ Profiling capabilities

**When to use:**

- Performance profiling
- Production debugging
- Performance optimization

## Runtime Mode Detection

You can detect the current run mode in your application:

```dart
class MyService {
  void logMessage(String message) {
    if (kDebugMode) {
      print('DEBUG: $message');
    } else if (kProfileMode) {
      print('PROFILE: $message');
    } else if (kReleaseMode) {
      // Log to file or external service
      _logToExternalService(message);
    }
  }
}
```

## Command Arguments

You can pass additional arguments to your application using the `--` separator:

```bash
dart run revali dev -- --port 8081 --host="0.0.0.0" --verbose
```

### Accessing Arguments in Your App

Arguments are automatically parsed and available in your `AppConfig`:

```dart title="routes/main_app.dart"
import 'package:revali_annotations/revali_annotations.dart';

@App()
class MainApp extends AppConfig {
  MainApp(Args args) : super(
    host: args['host'] ?? 'localhost',
    port: int.parse(args['port'] ?? '8080'),
  );

  @override
  Future<void> configureDependencies(DI di) async {
    // Access verbose flag
    final verbose = args['verbose'] == 'true';
    di.registerSingleton<Logger>(Logger(verbose: verbose));
  }
}
```

### Args Object Structure

The `Args` object provides structured access to command-line arguments:

```dart
Args {
  values: {
    'port': '8081',
    'host': '0.0.0.0',
    'verbose': 'true',
  },
  flags: {
    'verbose': true,
    'debug': false,
  },
  rest: ['additional', 'arguments'],
}
```

## Development Workflow

### 1. Start Development Server

```bash
dart run revali dev
```

### 2. Make Changes

Edit your controller files in the `routes/` directory:

```dart title="routes/user_controller.dart"
@Controller('/users')
class UserController {
  @Get('/')
  Future<List<User>> getUsers() async {
    return await userService.getAllUsers();
  }

  @Post('/')
  Future<User> createUser(@Body() CreateUserRequest request) async {
    return await userService.createUser(request);
  }
}
```

### 3. Hot Reload

Changes are automatically detected and applied:

- Save your file
- Hot reload triggers automatically
- Test your changes immediately

### 4. Debug Issues

Connect your IDE debugger:

- VS Code: `Ctrl+Shift+P` → `Dart: Attach to Process`
- IntelliJ: `Run` → `Edit Configurations` → `Dart Remote Debug`

## Troubleshooting

### Common Issues

**Port Already in Use:**

```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>

# Or use different port
dart run revali dev -- --port 8081
```

**Hot Reload Not Working:**

- Ensure files are in `routes/` directory
- Check file naming conventions
- Verify no syntax errors

**Debugger Not Connecting:**

- Check VM service URL format
- Verify IDE extensions are installed

## Next Steps

- **[Hot Reload](/revali/getting-started/hot-reload)**: Learn about automatic code reloading
- **[Debug Server](/revali/getting-started/debug-server)**: Debug your server code
- **[App Configuration](/revali/app-configuration/overview)**: Configure your application settings
