---
title: revali build
---

# The Build Command

The `revali build` command is used to run the ["Build Constructs"](/constructs). Which are used to generate code, assets, or any other files that are needed for deployment.

## Usage

```bash
revali build --help
```

## Run Modes

You can build your application in either `Release` or `Profile` mode. By default, the application will be built the in `Release` mode.

### Release Mode

In `Release` mode, the build will generate code that is optimized for performance. This mode is used for deploying your application.

To build the application in `Release` mode, use the `--release` flag.

```bash
dart run revali build --release
```

### Profile Mode

Profile mode generates the same optimized code as `Release` mode. The difference is that Profile mode will enable revali logs to be printed to the console.
