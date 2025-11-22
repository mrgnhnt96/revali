---
sidebar_position: 5
description: Configure constructs and other settings for Revali
---

# Revali Configuration

Revali uses a `revali.yaml` configuration file to manage constructs, settings, and project-specific options. This file allows you to enable, disable, and configure constructs, as well as customize Revali's behavior for your project.

## What is revali.yaml?

The `revali.yaml` file is Revali's main configuration file that:

- **Manages Constructs**: Enable, disable, and configure code generation constructs

## File Location

Create the `revali.yaml` file in the root of your project:

```tree
your_project/
├── lib/
├── routes/
├── pubspec.yaml
├── revali.yaml          # Revali configuration file
└── README.md
```

## Basic Configuration

A minimal `revali.yaml` file looks like this:

```yaml title="revali.yaml"
# Revali Configuration
version: "1.0.0"

# Constructs configuration
constructs:
  - name: revali_server
    enabled: true
  - name: revali_docker
    enabled: true
```

## Constructs Configuration

### Enable Constructs

By default, all constructs are enabled. To explicitly enable a construct, add it to the `constructs` list:

```yaml title="revali.yaml"
constructs:
  - name: revali_server
    enabled: true
  - name: revali_docker
    enabled: true
  - name: revali_client
    enabled: true
```

### Disable Constructs

To disable a construct, set the `enabled` field to `false`:

```yaml title="revali.yaml"
constructs:
  - name: revali_docker
    enabled: false # Disable Docker construct
  - name: revali_client
    enabled: true
```

### Construct Name Conflicts

If you have constructs with conflicting names, use the `package` field to specify the package:

```yaml title="revali.yaml"
constructs:
  - name: revali_docker
    package: revali_server # Specify package to avoid conflicts
    enabled: true
  - name: custom_docker
    package: my_custom_package
    enabled: true
```

:::note
The `package` value should match the package name in your `pubspec.yaml` file.
:::

### Configure Constructs

Some constructs offer additional configuration options. Use the `options` field to configure them:

```yaml title="revali.yaml"
constructs:
  - name: revali_docker
    enabled: true
    options:
      baseImage: "dart:3.0-slim"
      port: 8080
      environment: "production"
  - name: revali_client
    enabled: true
    options:
      outputDir: "lib/generated"
      generateTypes: true
```

:::tip
Check each construct's documentation for available configuration options.
:::

## Next Steps

- **[Constructs Overview](/constructs)**: Learn about Revali's construct system
- **[App Configuration](/revali/app-configuration/overview)**: Configure your application settings
- **[Environment Variables](/revali/app-configuration/env-vars)**: Manage environment-specific settings
