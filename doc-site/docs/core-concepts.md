# Core Concepts

## Annotations and Routing

### Using Controllers

Controllers are essential for grouping related request handlers. They are defined using the `@Controller` annotation. Here’s an example:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/example")
class ExampleController {
  @Get()
  Future<void> exampleMethod() async {
    // Method logic
  }
}
```

### Defining Routes with Annotations

Routes are defined using HTTP method annotations on controller methods. Supported annotations include `@Get`, `@Post`, `@Put`, and `@Delete`:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/example")
class ExampleController {

  @Get('/list')
  Future<void> getList() async {
    // Get logic
  }

  @Post('/create')
  Future<void> createItem() async {
    // Post logic
  }

  @Put('/update/{id}')
  Future<void> updateItem(@Param("id") String id) async {
    // Put logic
  }

  @Delete('/delete/{id}')
  Future<void> deleteItem(@Param("id") String id) async {
    // Delete logic
  }
}
```

## Dependency Injection

### Registering Dependencies

Revali uses a dependency injection (DI) system to manage the creation and provision of instances in your application. Register dependencies using the `DI` class.

```dart
@App(flavor: 'dev')
class DevApp extends AppConfig {
  @override
  Future<void> configureDependencies(DI di) async {
    di.register<SomeService>(SomeServiceImpl.new);
  }
}
```

### Configuring Dependencies

After registering your dependencies, you can inject them into your controllers:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/example")
class ExampleController {
  final SomeService someService;

  ExampleController(this.someService);

  @Get()
  Future<void> exampleMethod() async {
    // Use someService
    someService.performAction();
  }
}
```

This approach ensures that your dependencies are appropriately managed and can be easily replaced or mocked for testing purposes.
