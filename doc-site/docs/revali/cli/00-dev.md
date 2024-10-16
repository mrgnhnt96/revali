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
dart run revali dev --help
```

## Run Modes

You can develop your application in either `Release` or `Debug` mode. By default, the application will run in `Debug` mode.

### Debug Mode

In `Debug` mode, a Dart VM service will be started for your application. This allows you to connect to your application using the Dart DevTools or other debugging tools.

To run the application in `Debug` mode, use the `--debug` flag.

```bash
dart run revali dev --debug
```

### Release Mode

In `Release` mode, the Dart VM service will not be started. In this mode constructs can generate code that is optimized for performance.

To run the application in `Release` mode, use the `--release` flag.

```bash
dart run revali dev --release
```

Constructs can generate code that is optimized for performance in `Release` mode.

::::tip
Use debug mode during development.
:::info
This is the default mode for `revali build`.
:::
::::
