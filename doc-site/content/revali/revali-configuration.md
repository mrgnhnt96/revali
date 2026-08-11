---
title: Revali Configuration
description: Configure constructs and other settings for Revali
---

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

<CodeFile name="revali.yaml">

```yaml
# Constructs configuration
constructs:
  - name: revali_docker
    enabled: true
```

</CodeFile>

## Hot Reload Configuration

Customize which paths trigger hot reload during development:

<CodeFile name="revali.yaml">

```yaml
hot_reload:
  exclude:
    - lib/generated    # exclude directory (relative to revali.yaml)
    - docs             # exclude docs folder
    - /tmp/cache       # absolute paths also supported
```

</CodeFile>

Paths in `exclude` can be:

- **Relative** - resolved from the `revali.yaml` file location (typically project root)
- **Absolute** - used as-is

Excluding a directory ignores all file changes within it. Excluding a file ignores only that file.

## Constructs Configuration

### Enable Constructs

By default, all constructs are enabled. To explicitly enable a construct, add it to the `constructs` list:

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_docker
    enabled: true
  - name: revali_client
    enabled: true
```

</CodeFile>

### Disable Constructs

To disable a construct, set the `enabled` field to `false`:

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_docker
    enabled: false # Disable Docker construct
  - name: revali_client
    enabled: true
```

</CodeFile>

### Construct Name Conflicts

If you have constructs with conflicting names, use the `package` field to specify the package:

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: docs
    package: revali_swagger # Specify package to avoid conflicts
    enabled: true
  - name: docs
    package: my_custom_package
    enabled: true
```

</CodeFile>

<Callout type="note">

The `package` value should match the package name in your `pubspec.yaml` file.

</Callout>

### Configure Constructs

Some constructs offer additional configuration options. Use the `options` field to configure them:

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_swagger
    enabled: true
    options:
      title: My API
      version: 2.1.0
  - name: revali_client
    enabled: true
    options:
      package_name: my_api_client
      scheme: https
```

</CodeFile>

<Callout type="tip">

Check each construct's documentation for available configuration options.

</Callout>

## Build Configuration

Adding a `build:` section tells `revali build` to compile your server into a native executable, rather than leaving compilation to a build construct:

<CodeFile name="revali.yaml">

```yaml
build:
  target_os: linux
  target_arch: [x64, arm64]
```

</CodeFile>

See [`revali build`](/revali/cli/build#compiling-a-native-executable) for the full field reference.

## Next Steps

- **[Constructs Overview](/constructs)**: Learn about Revali's construct system
- **[App Configuration](/revali/app-configuration)**: Configure your application settings
- **[Environment Variables](/revali/app-configuration/env-vars)**: Manage environment-specific settings
