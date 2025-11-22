---
title: Installation
description: Learn how to install Revali Client and its dependencies
sidebar_position: 0
---

# Installation

Welcome to Revali Client! This guide will help you set up everything you need to generate type-safe client code for your Revali Server.

:::note
**Prerequisite**: This guide assumes you have already installed [Revali Server][revali-server]. If you haven't, please see the [Revali Server Installation][revali-server-installation] guide first.
:::

## Quick Start

The fastest way to get started is to add both required dependencies at once:

```bash
# Add runtime dependency
dart pub add revali_client

# Add code generator
dart pub add revali_client_gen --dev

# Get all dependencies
dart pub get
```

That's it! You're ready to generate your client code.

## Understanding the Dependencies

Revali Client consists of two main packages that work together to generate and run your client code:

### 📦 Revali Client (Runtime)

The runtime package that your generated client code depends on.

```bash
dart pub add revali_client
```

**What it provides:**

- `RevaliClient` - The underlying HTTP client
- `Storage` - Cookie and session storage interfaces
- `HttpInterceptor` - Request/response interception
- `ServerException` - Standardized error handling
- `HttpRequest` / `HttpResponse` - HTTP primitives

**Why it's needed:** This package contains the core runtime classes that the generated client uses to make HTTP requests, handle responses, and manage state.

### ⚙️ Revali Client Gen (Code Generator)

The code generator that creates your client implementation during the build process.

```bash
dart pub add revali_client_gen --dev
```

**What it provides:**

- Analyzes your Revali Server routes
- Generates type-safe data source interfaces
- Creates concrete HTTP client implementations
- Handles serialization and deserialization
- Manages the generated package structure

**Why it's needed:** This is a build-time dependency that runs during `revali dev` or `revali build` to generate the actual client code from your server definitions.

:::info
**Build Construct**: Revali Client Gen is a [Build Construct](/constructs#build-constructs), which means it runs during the build process and generates code in the `.revali/` directory.
:::

## Manual Installation

If you prefer to add dependencies manually, update your `pubspec.yaml` file:

```yaml title="pubspec.yaml"
dependencies:
  revali_client: ^<latest-version> # Runtime package

dev_dependencies:
  revali_client_gen: ^<latest-version> # Code generator
```

:::tip
**Version Matching**: It's recommended to keep `revali_client` and `revali_client_gen` on the same version to ensure compatibility.

Check [pub.dev](https://pub.dev/packages/revali_client) for the latest versions.
:::

## Configuration

After installation, you need to enable Revali Client in your `revali.yaml` configuration file:

```yaml title="revali.yaml"
constructs:
  - name: revali_client
    options:
      package_name: client # Optional: customize package name
      server_name: Server # Optional: customize server class name
```

:::tip
Learn more about [configuration options](/constructs/revali_client/getting-started/configure) to customize your client generation.
:::

## Directory Structure

Once installed and configured, Revali Client will generate code in the following structure:

```text
your_project/
├── .revali/
│   └── revali_client/          # Generated client package
│       ├── lib/
│       │   ├── client.dart
│       │   ├── interfaces.dart
│       │   └── src/
│       └── pubspec.yaml
├── lib/
├── routes/                     # Your server routes
└── pubspec.yaml
```

The generated client in `.revali/revali_client/` is a complete Dart package that you can import and use in your application.

## Common Issues

### Generated Code Not Updating

If the client isn't regenerating:

1. Ensure `revali_client_gen` is in `dev_dependencies`
2. Check that `revali.yaml` has the client construct enabled
3. Try running `revali build` or `revali dev` again

## What's Next?

Now that you have Revali Client installed, you're ready to:

1. **[Configure](/constructs/revali_client/getting-started/configure)** - Set up client generation options
2. **[Generate Client Code](/constructs/revali_client/generated-code)** - Understand the generated structure
3. **[Use HTTP Interceptors](/constructs/revali_client/getting-started/http-interceptors)** - Add request/response handling
4. **[Set Up Storage](/constructs/revali_client/getting-started/storage)** - Manage cookies and sessions

Ready to configure your client? Let's move on to [configuration](/constructs/revali_client/getting-started/configure)!

[revali-server]: ../../revali_server/overview.md
[revali-server-installation]: ../../revali_server/getting-started/installation.md
