---
sidebar_position: 0
description: Learn how to install Revali and its constructs
---

# Installation

This guide will walk you through installing Revali and setting up your first project.

## Prerequisites

- [Dart SDK](https://dart.dev/get-dart) (version 3.0.0 or higher)
- A code editor (VS Code recommended with Dart extension)

## Install Revali

Add `revali` to your project's dev dependencies. You can do this in two ways:

### Option 1: Using Dart CLI (Recommended)

```bash
dart pub add revali --dev
```

### Option 2: Manual Installation

Add the following to your `pubspec.yaml` file:

```yaml title="pubspec.yaml"
dev_dependencies:
  revali: ^1.0.0
```

:::note
Replace `^1.0.0` with the latest version from [pub.dev](https://pub.dev/packages/revali).
:::

## Install a Server Construct

Revali requires a server construct to generate the actual server code. The most common choice is `revali_server`:

### Install Revali Server

```bash
dart pub add revali_server --dev
```

Or manually add to `pubspec.yaml`:

```yaml title="pubspec.yaml"
dev_dependencies:
  revali_server: ^1.0.0
```

## Install Runtime Dependencies

For server functionality, you'll also need the runtime dependencies:

```bash
dart pub add revali_router
```

Or add to `pubspec.yaml`:

```yaml title="pubspec.yaml"
dependencies:
  revali_router: ^1.0.0
```

## Get Dependencies

After adding all dependencies, run:

```bash
dart pub get
```

## Verify Installation

Create a simple test to verify everything is working:

```bash
dart run revali --version
```

:::tip
Ready to create your first endpoint? Check out the [Create Your First Endpoint](/revali/getting-started/create-your-first-endpoint) guide.
:::

## Available Constructs

Revali supports various constructs for different use cases:

- **[revali_server](/constructs/revali_server/overview)**: Generate server-side code (most common)
- **[revali_client](/constructs/revali_client/overview)**: Generate client-side code
- **[revali_docker](/constructs/revali_docker/overview)**: Docker deployment support

Browse all available constructs on [pub.dev](https://pub.dev/packages?q=dependency%3Arevali_construct).
