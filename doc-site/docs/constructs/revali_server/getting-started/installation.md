---
title: Installation
description: Get up and running with Revali Server in minutes
sidebar_position: 0
---

# Installation

Welcome to Revali Server! This guide will help you set up everything you need to start building powerful Dart web servers.

## Quick Start

The fastest way to get started is to add all required dependencies at once:

```bash
# Add runtime dependencies
dart pub add revali_router

# Add development dependencies
dart pub add revali revali_server --dev

# Get all dependencies
dart pub get
```

That's it! You're ready to start building your server.

## Understanding the Dependencies

Revali Server is built on a foundation of three key packages, each serving a specific purpose:

### 🚀 Revali (Development Tool)

The core framework that orchestrates your entire development experience.

```bash
dart pub add revali --dev
```

**Why it's needed:** Revali provides the build system, CLI tools, and development server that make everything work together seamlessly.

### 🛣️ Revali Router (Runtime)

The routing engine that handles all HTTP requests and responses.

```bash
dart pub add revali_router
```

**Why it's needed:** This is the heart of your server - it processes incoming requests, matches them to your controllers, and sends back responses.

### ⚙️ Revali Server (Code Generator)

The code generator that creates your server implementation.

```bash
dart pub add revali_server --dev
```

**Why it's needed:** This package analyzes your code and generates the actual server files that Revali Router uses at runtime.

## Manual Installation

If you prefer to add dependencies manually, here's what your `pubspec.yaml` should look like:

```yaml title="pubspec.yaml"
dependencies:
  revali_router: ^1.0.0 # Runtime routing

dev_dependencies:
  revali: ^1.0.0 # Development framework
  revali_server: ^1.0.0 # Code generator
```

:::tip
Always use the latest versions! Check [pub.dev](https://pub.dev) for the most recent releases.
:::

## What's Next?

Now that you have Revali Server installed, you're ready to:

1. **[Use the CLI](./cli.md)** - Learn about the powerful command-line tools
2. **[Create your first endpoint](./create-your-first-endpoint.md)** - Build your first API endpoint
3. **[Run your server](./run-the-server.md)** - Start developing and see your changes live

Ready to dive in? Let's start with the CLI tools!
