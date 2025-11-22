---
title: Overview
slug: /create-constructs
sidebar_position: 0
---

# Create Constructs

Revali's construct system is designed to be intuitive and flexible, allowing developers to create powerful extensions and plugins for their applications. Whether you need a client-generated package, a Swagger API generator, or a custom deployment tool, Revali provides the tools to build and manage these constructs with ease.

## What You Can Build

Constructs enable you to extend Revali's capabilities in countless ways:

### 🚀 **Server Constructs**

- Custom HTTP servers with specialized protocols
- WebSocket servers with real-time capabilities
- gRPC servers for microservice communication
- GraphQL servers with schema generation

### 📦 **Build Constructs**

- Client SDK generation for multiple languages
- API documentation generators (OpenAPI, Swagger)
- Deployment configurations (Docker, Kubernetes)
- Asset bundlers and optimizers
- Database migration tools
- Testing utilities and mock generators

### 🔧 **Generic Constructs**

- Code generators for specific patterns
- Utility libraries with code generation
- Framework integrations
- Custom annotation processors

## Construct Types

Revali supports different types of constructs, each optimized for specific use cases:

### Server Constructs

Server constructs generate the core server implementation for your application. They run during development and provide the runtime foundation for your API.

**Characteristics:**

- Generate code in `.revali/server/` directory
- Handle HTTP requests and responses
- Provide middleware, routing, and lifecycle management
- **Limit**: One per project (ensures single server implementation)

### Build Constructs

Build constructs generate code, assets, or files needed for deployment and distribution. They run during the build process and prepare your application for production.

**Characteristics:**

- Generate code in `.revali/build/` directory
- Run during build command execution
- Prepare assets for deployment
- **Limit**: Multiple allowed (enables complex build pipelines)

### Generic Constructs

Generic constructs are flexible packages that can generate any type of code or assets. They're automatically detected and can be used for various purposes.

**Characteristics:**

- Generate code in `.revali/<construct-name>/` directory
- Flexible output structure
- Can be used for any code generation purpose
- **Limit**: Multiple allowed with automatic conflict resolution

## Directory Structure

When you create a construct, Revali automatically manages the generated output:

```tree
.revali/
├── server/              # Server construct output
├── build/               # Build construct output
├── my_custom_construct/ # Generic construct output
└── another_construct/   # Another generic construct
```

### Conflict Resolution

If multiple constructs have the same name, Revali automatically resolves conflicts by nesting them under their package names:

```tree
.revali/
├── package_a/
│   └── my_construct/
└── package_b/
    └── my_construct/
```

This ensures no conflicts while maintaining clear organization.

## Getting Started

Ready to create your first construct? Follow these guides:

1. **[Create a Package](/create-constructs/getting-started/create-package)** - Set up your construct package
2. **[Add as Dependency](/create-constructs/getting-started/add-as-dependency)** - Integrate with Revali
3. **[Create Entrypoint](/create-constructs/getting-started/create-entrypoint)** - Define your construct's main logic
4. **[Run New Construct](/create-constructs/getting-started/run-new-construct)** - Test your construct

## Advanced Topics

For more complex constructs, explore these advanced concepts:

- **[Construct Lifecycle](/create-constructs/core/construct-lifecycle)** - Understand how constructs integrate with Revali
- **[Server Constructs](/create-constructs/core/server-construct)** - Build custom server implementations
- **[Build Constructs](/create-constructs/core/build-construct)** - Create deployment and build tools
- **[Generic Constructs](/create-constructs/core/generic-construct)** - Build flexible code generators

## Best Practices

### Design Principles

- **Single Responsibility**: Each construct should have a clear, focused purpose
- **Composability**: Design constructs to work well with others
- **Performance**: Optimize for fast code generation
- **Maintainability**: Write clean, well-documented code

### Naming Conventions

- Use descriptive, clear names
- Follow Dart package naming conventions

### Documentation

- Provide clear README files
- Document all configuration options
- Include usage examples
- Maintain up-to-date API documentation
<!--

## Community Constructs

The Revali community has created many useful constructs. Browse available constructs on [pub.dev](https://pub.dev/packages?q=dependency%3Arevali_construct) or contribute your own! -->

:::tip
**Need Help?** Check out the [Tips and Tricks](/create-constructs/tips-and-tricks) guide for common patterns and solutions.
:::
