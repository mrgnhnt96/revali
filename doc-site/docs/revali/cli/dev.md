---
title: revali dev
---

# The Dev Command

The `revali dev` command is used to start the server for your Revali application. This command will analyze your routes and generate the server code for your application.

By default, the server will be started on port `8080` and will serve the API at `/api`.

:::info
To configure the port and the API path, check out [App Configuration](/revali/app-configuration/overview).
:::

## Usage

```bash
revali dev --help
```

### Run Modes

You can develop your application in either `Release` or `Debug` mode. By default, the application will run in `Debug` mode. To run the application in `Release` mode, use the `--release` flag.

```bash
revali dev --release
```

Constructs can generate code that is optimized for performance in `Release` mode.

:::tip
Use debug mode during development.
:::

:::info
This is the default mode for `revali build`.
:::
