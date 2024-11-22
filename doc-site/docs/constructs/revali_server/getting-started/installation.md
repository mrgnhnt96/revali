---
title: Installation
description: Learn how to install Revali Server and its dependencies
sidebar_position: 0
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
Make sure to replace `<latest-version>` with the latest version of [Revali][revali-pub].
:::

### Revali Router

Under the hood, Revali Server uses [Revali Router][revali-router-pub] to handle the request routing.

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
Make sure to replace `<latest-version>` with the latest version of [Revali Router][revali-router-pub].
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
Make sure to replace `<latest-version>` with the latest version of [Revali Server][revali-server-pub].
:::

### Get Dependencies

After adding the dependencies to your `pubspec.yaml` file, get the dependencies for your project.

```bash
dart pub get
```

## Revali Server Dependencies

Revali Server is comprised of many packages, each serving a different purpose. Here are the runtime packages that make up Revali Server:

### `revali_router`

Handles the request routing for your application during runtime.

### `revali_router_annotations`

The annotations used by `revali_router`, such as `Middleware` and `ExceptionCatcher`

### `revali_router_core`

Contains the fundamental classes used by `revali_router`. Some classes can also be used as annotations.

### `revali_core`

Contains fundamental classes used by `revali`.

### `revali_annotations`

The annotations used by `revali` to define controllers and endpoints.

## Generalized Imports

The `revali_router` package depends on the packages needed for you to create any annotations or classes that you will need to define in your application. So instead of having to import many different packages, you can import the `revali_router` package, which will import all the necessary packages for you.

```dart
import 'package:revali_router/revali_router.dart';
```

[revali-pub]: https://pub.dev/packages/revali
[revali-server-pub]: https://pub.dev/packages/revali_server
[revali-router-pub]: https://pub.dev/packages/revali_router
