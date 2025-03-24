---
title: Installation
description: Learn how to install Revali Client and its dependencies
sidebar_position: 0
---

# Installation

:::note
This assumes that you have already installed [Revali Server][revali-server]. So if you haven't already, please see the [Revali Server Installation][revali-server-installation] guide.
:::

## Dependencies

### Revali Client

Revali Client contains the runtime code for your client, such as the `RevaliClient` and `Storage` classes. Since it is needed at runtime, add `revali_client` to the `dependencies` section of your `pubspec.yaml` file.

Run the following command to add `revali_client` to your project.

```bash
dart pub add revali_client
```

Or manually add the following to your `pubspec.yaml` file.

```yaml title="pubspec.yaml"
dependencies:
  revali_client: <latest-version>
```

:::note
Make sure to replace `<latest-version>` with the latest version of [Revali Client][revali-client-pub].
:::

### Revali Client Gen

Revali Client Gen is used by Revali to generate your client code and is not needed at runtime. So add `revali_client_gen` to the `dev_dependencies` section of your `pubspec.yaml` file.

Run the following command to add `revali_client_gen` to your project.

```bash
dart pub add revali_client_gen --dev
```

Or manually add the following to your `pubspec.yaml` file.

```yaml title="pubspec.yaml"
dev_dependencies:
  revali_client_gen: <latest-version>
```

:::note
Make sure to replace `<latest-version>` with the latest version of [Revali Client Gen][revali-client-gen-pub].
:::

### Get Dependencies

After adding the dependencies to your `pubspec.yaml` file, get the dependencies for your project.

```bash
dart pub get
```

## Revali Client Dependencies

Revali Client is comprised of many packages, each serving a different purpose. Here are the runtime packages that make up Revali Client:

### `revali_router`

Handles the request routing for your application during runtime.

### `revali_router_annotations`

The annotations used by `revali_router`, such as `LifecycleComponent` and `Body`

### `revali_core`

Contains fundamental classes used by `revali`.

### `revali_annotations`

The annotations used by `revali` to define controllers and endpoints.

[revali-client-gen-pub]: https://pub.dev/packages/revali_client_gen
[revali-client-pub]: https://pub.dev/packages/revali_client
[revali-server-installation]: ../../revali_server/getting-started/installation.md
[revali-server]: ../../revali_server/overview.md
