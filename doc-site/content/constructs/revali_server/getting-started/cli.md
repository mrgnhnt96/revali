---
title: CLI
description: Use the Revali Server CLI to accelerate your development workflow
---

The Revali Server CLI is your development companion, providing powerful code generation tools that help you build faster and more consistently. It's automatically available once you've completed the [installation](/constructs/revali_server/getting-started/installation).

## Getting Started

Scaffolding is built into the main Revali CLI:

```bash
dart run revali --help
dart run revali create --help
```

Other project tooling on `dart run revali`:

| Command | Purpose |
|---------|---------|
| `dev` / `build` | Generate and run / build |
| `routes` | List routes from `.revali/server/routes.json` (`--generate`, `--json`) |
| `doctor` | SDK, constructs, kernel cache, output freshness |
| `create` | Scaffold app/controller/lifecycle-component/pipe/observer files |

### MCP (agents)

From the app package directory (where `.revali/` is written), run `dart run revali_mcp` (package `packages/revali_mcp` on the path / as a path dependency). See root `AGENTS.md` for Cursor `mcp.json` snippet.

## Code Generation Made Easy

The `create` command is your gateway to rapid development. It generates boilerplate code for all major Revali Server components, following best practices and naming conventions.

### Interactive Mode

The easiest way to get started is with interactive mode:

```bash
dart run revali create
```

This will present you with a menu of available components to generate, making it perfect for beginners or when you're unsure what you need.

### Direct Component Creation

For faster development, you can create components directly:

#### Controllers

Generate API endpoint controllers with proper routing setup.

```bash
dart run revali create controller
```

**What you get:** A fully configured controller class with the `@Controller` annotation and example methods.

#### Apps

Create application configuration files for complex setups.

```bash
dart run revali create app
```

**What you get:** A complete app configuration with middleware, routing, and lifecycle management.

#### Lifecycle Components

Generate components that hook into the application lifecycle.

```bash
dart run revali create lifecycle-component # or lc for short
```

**What you get:** A component class with lifecycle method stubs and proper annotations.

#### Observers

Create event observers for monitoring and logging.

```bash
dart run revali create observer
```

**What you get:** An observer class with event handling methods and proper registration.

#### Pipes

Generate data transformation and validation pipes.

```bash
dart run revali create pipe
```

**What you get:** A pipe class with transformation logic and proper error handling.

## Customizing Your Project Structure

By default, the CLI generates components in standard locations, but you can customize this to match your project's organization.

### Default Structure

```
routes/
  ├── controllers/                  # Controllers go here
  └── app/                          # App configs go here
lib/
  └── components/
      ├── lifecycle_components/     # Lifecycle components
      ├── observers/                # Event observers
      └── pipes/                    # Data pipes

```

### Custom Configuration

Create a `revali.yaml` file in your project root to customize paths:

<CodeFile name="revali.yaml">

```yaml
server:
  create_path:
    # Use arrays for nested directories
    controller: ["routes", "controllers"]
    app: ["routes", "apps"]
    lifecycle_component: ["lib", "components", "lifecycle_components"]
    observer: ["lib", "components", "observers"]
    pipe: ["lib", "components", "pipes"]
```

</CodeFile>

### Path Configuration Options

- **Array format**: `["folder1", "folder2", "folder3"]` creates nested directories (`./folder1/folder2/folder3`)
- **String format**: `"folder"` creates a single directory (`./folder`)

## What's Next?

Now that you know how to use the CLI, you're ready to:

1. **[Create your first endpoint](/constructs/revali_server/getting-started/create-your-first-endpoint)** - Use the CLI to generate a controller and build your first API
2. **[Run the server](/constructs/revali_server/getting-started/run-the-server)** - Start the development server and see your code in action

Ready to build something amazing? Let's create your first endpoint!
