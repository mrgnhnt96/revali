---
title: Overview
description: Generate a Dockerfile for your Revali server with revali build, then build, run and deploy the image
---

`revali_docker` is a build construct that writes a `Dockerfile` for your server to `.revali/build/Dockerfile` every time you run `revali build`. The image contains only the AOT-compiled server on Alpine Linux. It has no options.

## Installation

```bash
dart pub add --dev revali_docker
```

<CodeFile name="pubspec.yaml">

```yaml
dev_dependencies:
  revali: ^3.3.3
  revali_docker: ^1.2.0
```

</CodeFile>

Nothing goes in `revali.yaml`.

### Listen on all interfaces

A server bound to `localhost` inside a container refuses every connection from outside it, while looking healthy. Build your app with `AppConfig.fromEnv()`, which binds `0.0.0.0` and reads the port from `PORT` (default `8080`):

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  MainApp() : super.fromEnv();
}
```

</CodeFile>

See [Environment Variables](/revali/app-configuration/env-vars) for `HOST`, `PORT` and other runtime settings.

## Build and run

```bash
dart run revali build
docker build -f .revali/build/Dockerfile -t my-app .
docker run -p 8080:8080 my-app
```

Run `docker build` from the project root: the Dockerfile copies the whole project into the image.

The server answers [`/healthz` and `/readyz`](/revali/app-configuration/health-probes) out of the box, outside the `/api` prefix, for your platform's health checks.

## The generated Dockerfile

Without a `build:` section in `revali.yaml`, the Dockerfile compiles the server inside Docker:

<CodeFile name=".revali/build/Dockerfile">

```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN rm pubspec_overrides.yaml || true

# Get dependencies
RUN dart pub get

# Build the server
RUN dart run revali build --release --type constructs --recompile

# Compile the server
RUN dart compile exe .revali/server/server.dart -o /app/server

FROM alpine:latest

# Install necessary dependencies for the Dart binary
RUN apk add --no-cache libc6-compat ca-certificates

# Copy the compiled server to the image
COPY --from=build /app/server /app/bin/server

# Run the server
CMD ["/app/bin/server"]
```

</CodeFile>

- The mode flag follows your command: `revali build --profile` writes `--profile`. `--release` is the default.
- `revali build --flavor <name>` adds `--flavor <name>` to the in-container build.
- `pubspec_overrides.yaml` is deleted inside the image, because local path overrides do not exist there. Dependencies must resolve from `pubspec.yaml` alone.

### `--dart-define` values

Defines passed to `revali build` become build arguments. Only the **names** go into the Dockerfile, so the values given to `revali build` are not used by the image. Supply the real values at image build time:

```bash
dart run revali build --dart-define=API_KEY=dev --dart-define=REGION=dev
docker build --build-arg API_KEY=prod-key --build-arg REGION=eu \
  -f .revali/build/Dockerfile -t my-app .
```

```dockerfile
# Define build arguments
ARG API_KEY
ARG REGION

RUN dart compile exe .revali/server/server.dart -o /app/server -DAPI_KEY=$API_KEY \
	-DREGION=$REGION
```

## Cross-compiling

Add a `build:` section to `revali.yaml` and `revali build` compiles the server on your machine with `dart compile exe --target-os --target-arch`. Cross-compiling to Linux works from macOS, Windows or Linux with no extra toolchain.

<CodeFile name="revali.yaml">

```yaml
build:
  target_os: linux
  target_arch: [x64, arm64]
```

</CodeFile>

`revali_docker` then copies each binary into `.revali/build/` as `server-<arch>` (`server-amd64`, `server-arm64`, ...) and writes a single-stage Dockerfile around them:

```dockerfile
FROM alpine:latest

# Install necessary dependencies for the Dart binary
RUN apk add --no-cache libc6-compat ca-certificates

ARG TARGETARCH
COPY .revali/build/server-${TARGETARCH} /app/bin/server
RUN chmod +x /app/bin/server

# Run the server
CMD ["/app/bin/server"]
```

With one architecture the `COPY` names the file directly instead of using `TARGETARCH`. With several, build them in one go with buildx:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -f .revali/build/Dockerfile -t my-app .
```

In this mode `--dart-define` values are compiled into the binary at `revali build` time, not passed as build arguments. Native (FFI) libraries your app loads are not cross-compiled. See [Compiling a native executable](/revali/cli/build#compiling-a-native-executable) for `strip_debug_info` and the other `build:` keys.

If your `.dockerignore` excludes `.revali/`, re-include the binaries. Docker cannot re-include a path whose parent directory is excluded, so exclude the children instead:

<CodeFile name=".dockerignore">

```text
.revali/*
!.revali/build
```

</CodeFile>

## Deploying

The image runs on any container platform. Set `PORT` if the platform assigns one, point its health check at `/healthz`, and set runtime secrets as environment variables. For a step-by-step example, see [Deploy to Fly.io](/constructs/revali_docker/deploy/fly-io). To run several services together, see [`revali compose`](/revali/cli/compose).
