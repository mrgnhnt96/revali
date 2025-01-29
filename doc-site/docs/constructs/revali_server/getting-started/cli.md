---
title: CLI
description: Learn how to use the Revali CLI to create components for your Revali application.
sidebar_position: 1
---

# Revali Server CLI

The Revali Server CLI is a tool that can be used to enhance the development of your Revali application. The CLI is installed when you add `revali_server` as a dev dependency during the [installation][installation] process.

## Commands

### Create

The `create` command is used to generate components for your Revali application. The following components can be generated using the `create` command:

- [App]

    ```bash
    dart run revali_server create app
    ```

- [Controller]

    ```bash
    dart run revali_server create controller
    ```

- [Lifecycle Component]

    ```bash
    dart run revali_server create lifecycle-component
    ```

- [Observer]

    ```bash
    dart run revali_server create observer
    ```

- [Pipe]

    ```bash
    dart run revali_server create pipe
    ```

:::tip
You can choose from a list of available options by running the `create` command without any arguments.

```bash
dart run revali_server create
```

:::

## Configuration

Each of the components using the `create` command are generated into specific folders within your Revali application. If you would like to change the default configuration, you can do so by creating a `revali.yaml` file in the root of your project.

The following is an example of a `revali.yaml` file containing the default configuration:

```yaml title="revali.yaml"
revali_server:
    create_path:
        app: [ "routes", "app" ]
        controller: [ "routes", "controllers" ]
        lifecycle_component: [ "components", "lifecycle_components" ]
        observer: [ "components", "observers" ]
        pipe: [ "components", "pipes" ]
```

The `create_path` configuration allows you to specify the folder structure for each component type. The value of each component type can be either a string or a list of strings.

[installation]: ./installation.md
[controller]: ../core/controllers.md
[app]: ../../../revali/app-configuration/create-an-app.md
[lifecycle component]: ../lifecycle-components/components.md
[observer]: ../lifecycle-components/observer.md
[pipe]: ../core/pipes.md
