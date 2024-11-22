---
title: Overview
sidebar_position: 0
---

# Revali Docker

Revali Docker is a [Build Construct][build-construct] that creates a `Dockerfile` for a Revali server.

:::note
The use of this construct is not limited to [Revali Server][revali-server], it can be used to build Docker images for any Revali application.
:::

## Usage

To generate the `Dockerfile`, run the following command:

```bash
dart run revali build
```

This will generate a `Dockerfile` within the `.revali/build` directory.

Here is an example of a generated `Dockerfile`:

```bash title="terminal"
dart run revali build --dart-define=KEY=VALUE
```

```dockerfile title="Dockerfile"
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN rm pubspec_overrides.yaml || true

# Get dependencies
RUN dart pub get

# Define build arguments
ARG KEY=VALUE

# Build the server
RUN dart run revali build  --release --type constructs --recompile

# Compile the server
RUN dart compile exe .revali/server/server.dart -o /app/server -DKEY=$KEY

FROM alpine:latest

# Install necessary dependencies for the Dart binary
RUN apk add --no-cache libc6-compat ca-certificates

# Copy the compiled server to the image
COPY --from=build /app/server /app/bin/server

# Run the server
CMD ["/app/bin/server"]
```

### Arguments

#### Run Modes

The Dockerfile will mirror the run mode provided in the `revali build` command. So, if you run `revali build --release`, the Dockerfile will also build the server in release mode.

:::tip
Learn more about [Run Modes][run-modes].
:::

#### Dart Defines

You can pass Dart defines to the `revali build` command, and they will be used to create `ARG`s in the Dockerfile (so you can override them with different values if needed). Then the `ARG` values will be passed to the `dart compile` command.

:::tip
Learn more about [env vars][env-vars]
:::

[build-construct]: ../../constructs/overview.md#build-constructs
[revali-server]: ../revali_server/overview.md
[run-modes]: ../../revali/cli/build.md#run-modes
[env-vars]: ../../revali/app-configuration/env-vars.md
