# Revali

Revali is a powerful code generator specifically designed for the Dart programming language. By leveraging annotations within your classes, methods, and method parameters, Revali manages the boilerplate code for you, allowing developers to focus on writing clean and maintainable code.

## Table of Contents

- [Revali](#revali)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Features](#features)
  - [Installation](#installation)
  - [Getting Started](#getting-started)
    - [Setting Up Your App](#setting-up-your-app)
    - [Starting the Server](#starting-the-server)
  - [Usage](#usage)
    - [Creating a Controller](#creating-a-controller)
    - [Handling WebSockets](#handling-websockets)
  - [Contributing](#contributing)
  - [Developer Information](#developer-information)
    - [Available Scripts](#available-scripts)
    - [Barrel](#barrel)
      - [Build Barrel](#build-barrel)
    - [Build Runner](#build-runner)
      - [Build](#build)
      - [Watch](#watch)
    - [Summary of Commands](#summary-of-commands)
    - [Scripts Resource](#scripts-resource)
  - [License](#license)

## Introduction

Revali aims to simplify API development in Dart by automating the creation of APIs. It provides a suite of tools and annotations to streamline various aspects of development, including routing, dependency injection, and WebSocket management.

## Features

- Annotation-based routing
- Dependency injection support
- WebSocket handling
- Interceptors and Middleware
- Guards for route protection
- Exception filters for error handling

## Installation

To install Revali, you need to add the necessary dependencies to your `pubspec.yaml`:

```yaml
dependencies:
    revali_router: <latest version>

dev_dependencies:
    revali: <latest version>
    revali_server: <latest version>
```

Replace `<latest version>` with the latest versions available on [pub.dev](https://pub.dev).

Run the following command to install the packages:

```sh
flutter pub get
```

## Getting Started

### Setting Up Your App

Create a basic app by defining a class that extends `AppConfig` from `revali_router`:

```dart
// routes/dev.app.dart
import 'package:revali_router/revali_router.dart';

@AllowOrigins.all()
@App(flavor: 'dev')
final class DevApp extends AppConfig {
  DevApp()
      : super(
          host: 'localhost',
          port: 8080,
        );

  @override
  Future<void> configureDependencies(DI di) async {}
}
```

**Note**: The file name must end in `.app.dart`.

### Starting the Server

In your main entry point, start the Revali server:

```dart
import 'package:revali_router/revali_router.dart';

void main() async {
  final app = DevApp();

  final server = await app.createServer();
  await server.listen();

  print('Server running on ${app.host}:${app.port}');
}
```

## Usage

### Creating a Controller

Define a controller using annotations to handle various HTTP requests:

```dart
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller("example")
class ExampleController {
  @Get('items')
  Future<List<String>> getItems() async {
    return ['item1', 'item2', 'item3'];
  }

  @Post('items')
  Future<void> createItem(@Body() Map<String, String> item) async {
    print('New item added: ${item['name']}');
  }
}
```

### Handling WebSockets

Create a WebSocket handler:

```dart
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/revali_router.dart';

class WebSocketHandlers {
  @WebSocket('ws', mode: WebSocketMode.twoWay)
  Stream<String> onMessage(String message) async* {
    yield 'Echo: $message';
  }
}
```

Register your WebSocket handler:

```dart
import 'package:revali_router/revali_router.dart';

@App(flavor: 'dev')
class DevApp extends AppConfig {
  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton((di) => WebSocketHandlers());
  }
}
```

## Contributing

We welcome contributions! Please follow these steps to contribute to Revali:

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally:

    ```sh
    git clone https://github.com/your-username/revali.git
    ```

3. **Create a branch** for your feature or bugfix:

    ```sh
    git checkout -b my-feature-branch
    ```

4. **Make your changes** and commit them:

    ```sh
    git commit -m "Description of my changes"
    ```

5. **Push to your branch**:

    ```sh
    git push origin my-feature-branch
    ```

6. **Open a Pull Request** on the original repository.

## Developer Information

To assist with development tasks, you can use the `sip_cli` pub package to run various scripts defined in the `scripts.yaml` file. This is similar to using the `scripts` section in a `package.json` file for Node.js projects.

### Available Scripts

Below are the available scripts you can run using `sip_cli`. These scripts simplify common development tasks, such as code generation and building packages.

### Barrel

#### Build Barrel

```sh
sip barrel
```

This command runs the `barreler build` command to build barrels in your project.

### Build Runner

The `build_runner` commands help manage and run code generation tasks.

#### Build

To run the build commands:

```sh
sip br b
```

This will execute:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Nested build commands include:

- **Build Revali Construct**:

    ```sh
    sip br b gen_core
    ```

    This runs:

    ```sh
    cd packages/revali_construct && dart run build_runner build --delete-conflicting-outputs
    ```

- **Build Revali Router**:

    ```sh
    sip br b router
    ```

    This runs:

    ```sh
    cd packages/revali_router && dart run build_runner build --delete-conflicting-outputs
    ```

#### Watch

To run the watch commands:

```sh
sip br w
```

This will execute:

```sh
dart run build_runner watch --delete-conflicting-outputs
```

Nested watch commands include:

- **Watch Revali Construct**:

    ```sh
    sip br w gen_core
    ```

    This runs:

    ```sh
    cd packages/revali_construct && dart run build_runner watch --delete-conflicting-outputs
    ```

- **Watch Revali Router**:

    ```sh
    sip br w router
    ```

    This runs:

    ```sh
    cd packages/revali_router && dart run build_runner watch --delete-conflicting-outputs
    ```

### Summary of Commands

Here is a summary of the available commands and their aliases for quick reference:

| Command             | Alias      | Description                    |
| ------------------- | ---------- | ------------------------------ |
| `sip barrel`        | -          | Build barrels                  |
| `sip br b`          | `build`    | Run build commands             |
| `sip br b gen_core` | `gen_core` | Build Revali Construct package |
| `sip br b router`   | `router`   | Build Revali Router package    |
| `sip br w`          | `watch`    | Run watch commands             |
| `sip br w gen_core` | `gen_core` | Watch Revali Construct package |
| `sip br w router`   | `router`   | Watch Revali Router package    |

Use these commands to streamline your development workflow and efficiently manage code generation and builds within the Revali project.

### Scripts Resource

Please refer to the [scripts.yaml](./scripts.yaml) file directly for an up to date listing of all commands.

## License

Revali is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
