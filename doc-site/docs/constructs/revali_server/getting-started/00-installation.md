---
title: Installation
---

# Installation

## Dependencies

### Revali

Revali Server is a part of the Revali framework. To use Revali Server, you will need to add Revali as a dev dependency to your project. This can be done by adding the following to the `dev_dependencies` section of your `pubspec.yaml` file.

Run the following command to add `revali` to your project.

```bash
dart pub add revali --dev
```

Or manually add the following to your `pubspec.yaml` file.

```yaml title="pubspec.yaml"
dev_dependencies:
  revali: <latest-version>
```

:::note
Make sure to replace `<latest-version>` with the latest version of [Revali](https://pub.dev/packages/revali).
:::

### Revali Router

Under the hood, Revali Server uses [Revali Router](https://pub.dev/packages/revali_router) to define routes. This package depends on all the runtime dependencies of Revali and exports them, making it easier to use `revali_server` in your project. This way, you don't need to have separate import statements for each package, you can just import `revali_router` and get all the necessary dependencies.

```dart
import 'package:revali_router/revali_router.dart';
```

Revali Router will be used during runtime, so it will need to be added under the `dependencies` section of your `pubspec.yaml` file.

Run the following command to add `revali_router` to your project.

```bash
dart pub add revali_router
```

Or manually add the following to your `pubspec.yaml` file.

```yaml title="pubspec.yaml"
dependencies:
  revali_router: <latest-version>
```

:::note
Make sure to replace `<latest-version>` with the latest version of [Revali Router](https://pub.dev/packages/revali_router).
:::

### Revali Server

Revali Server is used by Revali to generate your server code and is not needed at runtime. So add `revali_server` to the `dev_dependencies` section of your `pubspec.yaml` file.

Run the following command to add `revali_server` to your project.

```bash
dart pub add revali_server --dev
```

Or manually add the following to your `pubspec.yaml` file.

```yaml title="pubspec.yaml"
dev_dependencies:
  revali_server: <latest-version>
```

:::note
Make sure to replace `<latest-version>` with the latest version of [Revali Server](https://pub.dev/packages/revali_server).
:::

### Get Dependencies

After adding the dependencies to your `pubspec.yaml` file, get the dependencies for your project.

```bash
dart pub get
```
