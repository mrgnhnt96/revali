---
title: revali build
---

# The Build Command

The `revali build` command is used to run the ["Build Constructs"](/constructs). Which are used to generate code, assets, or any other files that are needed for deployment.

## Usage

```bash
revali build --help
```

### Run Modes

You can build your application in either `Release` or `Debug` mode. By default, the application will be built the in `Release` mode.

Building the application in Debug mode may be useful for debugging purposes, but may not be as optimized as building in Release mode.

:::note
Building your application in `Debug` mode _will not_ start up a Dart VM instance.
:::
