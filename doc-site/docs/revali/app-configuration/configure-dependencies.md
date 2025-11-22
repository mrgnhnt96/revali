---
sidebar_position: 2
description: Register and resolve dependencies for your controllers
---

# Configure Dependencies

Dependency injection is a powerful pattern that makes your code more modular, testable, and maintainable. Revali provides a built-in dependency injection system that allows you to register and resolve dependencies throughout your application.

## What is Dependency Injection?

Dependency injection (DI) is a design pattern where dependencies are provided to a class rather than the class creating them itself. This promotes:

- **Loose Coupling**: Classes depend on abstractions, not concrete implementations
- **Testability**: Easy to mock dependencies for unit testing
- **Flexibility**: Can swap implementations without changing dependent code
- **Maintainability**: Centralized dependency management

## How Revali DI Works

```mermaid
graph TD
    A[AppConfig] --> B[configureDependencies]
    B --> C[DI Container]
    C --> D[Resolve Services]
    C --> E[Resolve Repositories]
    C --> F[Resolve Controllers]

    G[Controller] --> H[Constructor Injection]
    H --> I[DI Container]
    I --> J[Resolve Dependencies]
    J --> K[Create Instance]
```

## Registering Dependencies

Use the `configureDependencies` method in your `AppConfig` class to register dependencies:

```dart title="routes/main_app.dart"
import 'package:revali_annotations/revali_annotations.dart';

@App()
class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    // Register your dependencies here
    di.registerLazySingleton<UserService>(UserServiceImpl.new);
    di.registerFactory<EmailService>(EmailServiceImpl.new);
    di.registerSingleton<DatabaseConnection>(DatabaseConnection());
  }
}
```

## Registration Methods

### `registerLazySingleton<T>`

Creates a single instance that's created only when first requested:

```dart
// Register a service as lazy singleton
di.registerLazySingleton<UserService>(UserServiceImpl.new);

// Usage in controller
class UserController {
  final UserService _userService;

  UserController(this._userService); // Injected automatically
}
```

**When to use:**

- Expensive to create (database connections, HTTP clients)
- Stateless services
- Shared resources across the application

### `registerSingleton<T>`

Registers an already instantiated object:

```dart
// Register a pre-created instance
final config = AppConfig(host: 'localhost', port: 8080);
di.registerSingleton<AppConfig>(config);

// Register environment-specific instances
di.registerSingleton<DatabaseConfig>(DatabaseConfig.fromEnv());
```

**When to use:**

- Configuration objects
- Pre-initialized resources
- Environment-specific instances

### `registerFactory<T>`

Creates a new instance every time it's requested:

```dart
// Register a factory for transient objects
di.registerFactory<Logger>(() => Logger.withTimestamp());

// Register with parameters
di.registerFactory<HttpClient>(() => HttpClient(timeout: Duration(seconds: 30)));
```

**When to use:**

- Stateful objects that shouldn't be shared
- Objects that need fresh state each time
- Temporary or request-scoped objects

## Using Abstractions

Register implementations against interfaces for better testability:

```dart title="routes/main_app.dart"
@override
Future<void> configureDependencies(DI di) async {
  // Register implementation against interface
  di.registerLazySingleton<IUserRepository>(UserRepository.new);
  di.registerLazySingleton<IEmailService>(EmailService.new);
  di.registerLazySingleton<IPaymentService>(StripePaymentService.new);
}
```

```dart title="lib/services/user_service.dart"
class UserService {
  final IUserRepository _userRepository;
  final IEmailService _emailService;

  UserService(this._userRepository, this._emailService);

  Future<User> createUser(CreateUserRequest request) async {
    final user = await _userRepository.create(request);
    await _emailService.sendWelcomeEmail(user.email);
    return user;
  }
}
```

## Complete Example

Here's a complete dependency configuration for a typical application:

```dart title="routes/main_app.dart"
import 'package:revali_annotations/revali_annotations.dart';

@App()
class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    // Database
    di.registerLazySingleton<DatabaseConnection>(() => DatabaseConnection.fromEnv());

    // Repositories
    di.registerLazySingleton<IUserRepository>(UserRepository.new);
    di.registerLazySingleton<IProductRepository>(ProductRepository.new);

    // Services
    di.registerLazySingleton<IUserService>(UserService.new);
    di.registerLazySingleton<IProductService>(ProductService.new);
    di.registerLazySingleton<IEmailService>(EmailService.new);

    // External APIs
    di.registerLazySingleton<IPaymentService>(StripePaymentService.new);
    di.registerLazySingleton<IAnalyticsService>(GoogleAnalyticsService.new);

    // Utilities
    di.registerFactory<Logger>(() => Logger.withTimestamp());
    di.registerSingleton<AppConfig>(this);
  }
}
```

## Dependency Resolution

Dependencies are automatically resolved when controllers are created:

```dart title="routes/user_controller.dart"
import 'package:revali_annotations/revali_annotations.dart';

@Controller('/users')
class UserController {
  final IUserService _userService;
  final IEmailService _emailService;

  // Dependencies are injected automatically
  UserController(this._userService, this._emailService);

  @Get('/')
  Future<List<User>> getUsers() async {
    return await _userService.getAllUsers();
  }

  @Post('/')
  Future<User> createUser(@Body() CreateUserRequest request) async {
    final user = await _userService.createUser(request);
    await _emailService.sendWelcomeEmail(user.email);
    return user;
  }
}
```

## Best Practices

### 🏗️ **Architecture**

- **Register by Interface**: Use interfaces for better testability
- **Group Related Dependencies**: Organize registrations logically
- **Use Appropriate Lifetimes**: Choose the right registration method for each dependency

### 🧪 **Testing**

- **Mock Dependencies**: Easy to replace implementations with mocks
- **Test Configuration**: Create separate DI configurations for testing
- **Isolate Dependencies**: Each test should have its own dependency instances

### 🚀 **Performance**

- **Lazy Singletons**: Use for expensive resources
- **Factory for Transients**: Use for objects that need fresh state
- **Avoid Over-Registration**: Only register what you actually need

### 🔒 **Security**

- **Environment Variables**: Use for sensitive configuration
- **Scoped Dependencies**: Limit dependency scope when possible
- **Validation**: Validate configuration values at startup

## Common Patterns

### Service Layer Pattern

```dart
// Repository (Data Access)
abstract class IUserRepository {
  Future<User?> findById(String id);
  Future<User> create(CreateUserRequest request);
}

// Service (Business Logic)
abstract class IUserService {
  Future<User> createUser(CreateUserRequest request);
  Future<User> getUserById(String id);
}

// Controller (API Layer)
@Controller('/users')
class UserController {
  final IUserService _userService;
  UserController(this._userService);
}
```

### Configuration Pattern

```dart
class DatabaseConfig {
  final String host;
  final int port;
  final String database;

  DatabaseConfig.fromEnv()
    : host = Platform.environment['DB_HOST'] ?? 'localhost',
      port = int.parse(Platform.environment['DB_PORT'] ?? '5432'),
      database = Platform.environment['DB_NAME'] ?? 'myapp';
}
```

## Troubleshooting

### Common Issues

**Dependency Not Found:**

- Ensure the dependency is registered in `configureDependencies`
- Check that the type matches exactly
- Verify the dependency is registered before it's needed

**Singleton State Issues:**

- Use factories for stateful objects

## Next Steps

- **[Environment Variables](/revali/app-configuration/env-vars)**: Handle configuration across environments
- **[Flavors](/revali/app-configuration/flavors)**: Create environment-specific configurations
