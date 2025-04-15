---
title: revali dev
sidebar_position: 0
description: Start the server and develop your Revali application
---

# The Dev Command

The `revali dev` command is used to start the server for your Revali application. This command will analyze your routes and generate the server code for your application.

By default, the server will be started on port `8080` and will serve the API at `/api`.

:::info
To configure the port and the API path, check out [App Configuration][app-config].
:::

## Usage

```bash
dart run revali dev --help
```

## Run Modes

You can develop your application in either `Release` or `Debug` mode. By default, the application will run in `Debug` mode.

### Debug Mode

In `Debug` mode, a Dart VM service (hot reload + debugger) will be started for your application. This allows you to connect to your application using the Dart DevTools or other debugging tools.

To run the application in `Debug` mode, use the `--debug` flag.

```bash
dart run revali dev --debug
```

:::tip
Use `kDebugMode` to check if the application is running in `Debug` mode during runtime.
:::

### Release Mode

In `Release` mode, the Dart VM service will not be started. In this mode constructs can generate code that is optimized for performance.

To run the application in `Release` mode, use the `--release` flag.

```bash
dart run revali dev --release
```

Constructs can generate code that is optimized for performance in `Release` mode.

::::tip
Use `kReleaseMode` to check if the application is running in `Release` mode during runtime.
:::info
This is the default mode for `revali build`.
:::
::::

### Profile Mode

Similar to `Release` mode, `Profile` mode will not start the Dart VM service. The main difference between `Release` and `Profile` mode is that `Profile` mode will continue to provide debug information during runtime. (Such as returning the stack trace in a response when an [error occurs][error-responses].)

To run the application in `Profile` mode, use the `--profile` flag.

```bash
dart run revali dev --profile
```

:::tip
Use `kProfileMode` to check if the application is running in `Profile` mode during runtime.
:::

## Arguments

You can pass additional arguments to the server by using the `--` separator in the command.

```bash
dart run revali dev -- --port 8081 --host="0.0.0.0" --debug loz
```

These would be the arguments parsed by the `Args` class.

```dart
Args {
    values: {
        'port': '8081',
        'host': '0.0.0.0',
        'debug': true,
    },
    flags: {
        'debug': true,
    },
    rest: ['loz'],
}
```

:::tip
The arguments can be accessed in your application by [binding] the `Args` class.

```dart
class MyApp extends AppConfig {
    MyApp(Args args) : super(host: args['host'], port: args['port']);
}
```

:::

[app-config]: ../app-configuration/overview.md
[error-responses]: ../../constructs/revali_server/lifecycle-components/overview.md#error-responses
[binding]: ../../constructs/revali_server/core/binding.md
