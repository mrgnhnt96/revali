# Examples and Tutorials

## CRUD Operations

### Creating, Reading, Updating, Deleting Endpoints

This example demonstrates how to set up basic CRUD operations using Revali.

### Create

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/items")
class ItemController {
  @Post('/create')
  Future<void> createItem(@Body() Item item) async {
    // Logic to create an item
    print('Item created: $item');
  }
}
```

### Read

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/items")
class ItemController {
  @Get('/')
  Future<List<Item>> getItems() async {
    // Logic to retrieve items
    return List<Item>.empty();
  }

  @Get('/{id}')
  Future<Item> getItem(@Param('id') String id) async {
    // Logic to retrieve a specific item
    return Item(id: id, name: 'Sample Item');
  }
}
```

### Update

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/items")
class ItemController {
  @Put('/update/{id}')
  Future<void> updateItem(@Param('id') String id, @Body() Item item) async {
    // Logic to update an item
    print('Item updated: $item');
  }
}
```

### Delete

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("/items")
class ItemController {
  @Delete('/delete/{id}')
  Future<void> deleteItem(@Param('id') String id) async {
    // Logic to delete an item
    print('Item deleted: $id');
  }
}
```

## Real-time Features

### Implementing WebSockets

This example demonstrates how to set up and use WebSockets for real-time features.

#### WebSocket Handler

Create a WebSocket handler and annotate the method with `@WebSocket`:

```dart
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/revali_router.dart';

class WebSocketHandlers {
  @WebSocket('/ws', mode: WebSocketMode.twoWay)
  Stream<String> onMessage(String message) async* {
    print('Received message: $message');
    yield 'Echo: $message';  // Echo the received message back to the client
  }
}
```

#### Integrate WebSocket Handler into App Configuration

Register the WebSocket handler in your `AppConfig` class:

```dart
import 'package:revali_router/revali_router.dart';

@App(flavor: 'dev')
class DevApp extends AppConfig {
  DevApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton((di) => WebSocketHandlers());
  }
}
```

#### Start the Server

Start the Revali server with WebSocket support in the main entry point:

```dart
import 'package:revali_router/revali_router.dart';

void main() async {
  final app = DevApp();

  final server = await app.createServer();
  await server.listen();

  print('Server running on ${app.host}:${app.port}');
}
```

With this setup, you can handle WebSocket connections and implement real-time communication features in your Revali application.
