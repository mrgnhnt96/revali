---
title: Installation
description: Learn how to install Revali and its constructs
---

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

<CodeFile name="pubspec.yaml">

```yaml
dev_dependencies:
  revali: ^1.0.0
```

</CodeFile>

<Callout type="note">

Replace `^1.0.0` with the latest version from [pub.dev](https://pub.dev/packages/revali).

</Callout>

## Install Runtime Dependencies

For server functionality, you'll also need the runtime dependencies:

```bash
dart pub add revali_router
```

Or add to `pubspec.yaml`:

<CodeFile name="pubspec.yaml">

```yaml
dependencies:
  revali_router: ^1.0.0
```

</CodeFile>

## Get Dependencies

After adding all dependencies, run:

```bash
dart pub get
```

## Verify Installation

Confirm the CLI resolves and your project's setup is healthy:

```bash
dart run revali doctor
```

<Callout type="tip">

Ready to create your first endpoint? Check out the [Create Your First Endpoint](/revali/getting-started/create-your-first-endpoint) guide.

</Callout>

## Available Constructs

Server-side code generation ([Revali Server](/constructs/revali_server)) is built into `revali` — nothing extra to install. Beyond that, Revali supports optional constructs for other use cases:

- **[revali_client](/constructs/revali_client)**: Generate client-side code
- **[revali_docker](/constructs/revali_docker)**: Docker deployment support

Browse all available constructs on [pub.dev](https://pub.dev/packages?q=dependency%3Arevali_construct).
