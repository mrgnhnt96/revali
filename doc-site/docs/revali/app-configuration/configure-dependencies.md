# Configure Dependencies

Your controllers will likely need to interact with other parts of your application. This could be a service, a repository, or even another controller. In most cases, you'll want to inject these dependencies into your controller. Revali makes this easy by providing a way to register and resolve dependencies.

## Registering Dependencies

To register a dependency, you'll need to use the `configureDependencies` method within your `AppConfig` class.

```dart title="routes/my_app.dart"
@App()
class MyApp extends AppConfig {
  ...

  // highlight-start
  Future<void> configureDependencies(DI di) async {
    di.register(MyService.new);
  }
  // highlight-end
}
```

### Using Abstractions

If you need to register a dependency as an abstraction, you can provide a type parameter to the `register` method.

```dart title="routes/my_app.dart"
@App()
class MyApp extends AppConfig {
  ...
  
  Future<void> configureDependencies(DI di) async {
    // highlight-next-line
    di.register<MyService>(MyServiceImpl.new);
  }
}
```

## The DI Object

The `DI` object is a dependency injection container that is passed to the `configureDependencies` method. You can use this object to register dependencies. The ["Server Construct"][server-construct] will use this object to resolve dependencies when creating Dart objects.

Everything registered will eventually become a "singleton". Meaning that the dependency will be cached in memory and reused for the lifetime of the application.

After the `configureDependencies` method is resolved, the `DI` object will be "closed" and no more dependencies can be registered.

### `register` Method

This is used to "lazy load" a dependency with the `DI` object. It takes a factory function that returns an instance of the dependency. When a dependency is resolved, the factory function will be called to create an instance of the dependency and store it to be used later.

```dart
void register<T>(T Function() factoryFunction);
```

### `registerInstance` Method

This is used to register an instance of a dependency with the `DI` object. This is useful when you need to register a dependency that is already instantiated.

```dart
void registerInstance<T>(T instance);
```

[server-construct]: ../../constructs/overview.md#server-constructs
