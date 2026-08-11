---
title: Installation
description: Get up and running with Revali Server in minutes
---

Welcome to Revali Server! This guide will help you set up everything you need to start building powerful Dart web servers.

## Quick Start

The fastest way to get started is to add both required dependencies at once:

```bash
# Add the runtime dependency
dart pub add revali_router

# Add the development dependency
dart pub add revali --dev

# Get all dependencies
dart pub get
```

That's it! You're ready to start building your server.

## Understanding the Dependencies

Revali Server is built on a foundation of two key packages, each serving a specific purpose:

### 🚀 Revali (Development Tool)

The core framework that orchestrates your entire development experience — including generating your server's code. No separate code-generator package to add.

```bash
dart pub add revali --dev
```

**Why it's needed:** Revali provides the build system, CLI tools, development server, and server code generation that make everything work together seamlessly.

### 🛣️ Revali Router (Runtime)

The routing engine that handles all HTTP requests and responses.

```bash
dart pub add revali_router
```

**Why it's needed:** This is the heart of your server - it processes incoming requests, matches them to your controllers, and sends back responses.

## Manual Installation

If you prefer to add dependencies manually, here's what your `pubspec.yaml` should look like:

<CodeFile name="pubspec.yaml">

```yaml
dependencies:
  revali_router: <latest> # Runtime routing

dev_dependencies:
  revali: <latest> # Development framework + server code generation
```

</CodeFile>

<Callout type="tip">

Always use the latest versions! Check [pub.dev](https://pub.dev) for the most recent releases.

</Callout>

## What's Next?

Now that you have Revali Server installed, you're ready to:

1. **[Use the CLI](/constructs/revali_server/getting-started/cli)** - Learn about the powerful command-line tools
2. **[Create your first endpoint](/constructs/revali_server/getting-started/create-your-first-endpoint)** - Build your first API endpoint
3. **[Run your server](/constructs/revali_server/getting-started/run-the-server)** - Start developing and see your changes live

Ready to dive in? Let's start with the CLI tools!
