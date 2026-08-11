---
title: Overview
description: Generate production-ready Dockerfiles for Revali applications
---

Revali Docker is a [Build Construct](/constructs#build-constructs) that automatically generates optimized, production-ready Dockerfiles for your Revali applications. It creates multi-stage Docker builds that compile your Dart server into an efficient, standalone executable.

## Overview

When you run `revali build`, the Docker construct automatically generates a `Dockerfile` configured specifically for your project. This Dockerfile uses a multi-stage build process to create a minimal, secure production image.

**Key features:**

- **Multi-stage builds** - Small final image size
- **Optimized compilation** - AOT-compiled Dart binaries
- **Environment variables** - Support for build-time configuration
- **Build mode support** - Respects release/profile modes
- **Secure base images** - Uses official Dart and Alpine Linux
- **Production-ready** - Includes only necessary runtime dependencies

<Callout type="note">

While designed for [Revali Server](/constructs/revali_server), Revali Docker can generate Dockerfiles for any Revali application.

</Callout>

---

## Quick Start

Generate a Dockerfile for your project:

```bash
dart run revali build
```

The generated `Dockerfile` will be created at:

```
.revali/build/Dockerfile
```

Build and run your Docker image:

```bash
# Build the image
docker build -f .revali/build/Dockerfile -t my-app .

# Run the container
docker run -p 8080:8080 my-app
```

---

## Generated Dockerfile Structure

Here's an example of a generated Dockerfile with explanations:

<CodeFile name=".revali/build/Dockerfile">

```dockerfile
# Stage 1: Build environment
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN rm pubspec_overrides.yaml || true

# Get dependencies
RUN dart pub get

# Build the server with Revali
RUN dart run revali build --release --type constructs --recompile

# Compile to native executable
RUN dart compile exe .revali/server/server.dart -o /app/server

# Stage 2: Runtime environment
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache libc6-compat ca-certificates

# Copy compiled server
COPY --from=build /app/server /app/bin/server

# Run the server
CMD ["/app/bin/server"]
```

</CodeFile>

---

## Build Modes

The generated Dockerfile respects the build mode specified in the `revali build` command.

### Release Mode (Default)

Generates a fully optimized production build:

```bash
dart run revali build --release
```

**Generated Dockerfile includes:**

```dockerfile
# Full optimizations enabled
RUN dart run revali build --release --type constructs --recompile
RUN dart compile exe .revali/server/server.dart -o /app/server
```

**Characteristics:**

- Maximum performance optimizations
- Smallest binary size
- No debug information
- Recommended for production

### Profile Mode

Generates an optimized build with profiling capabilities:

```bash
dart run revali build --profile
```

**Generated Dockerfile includes:**

```dockerfile
# Optimizations with profiling enabled
RUN dart run revali build --profile --type constructs --recompile
RUN dart compile exe .revali/server/server.dart -o /app/server
```

**Characteristics:**

- Performance optimizations
- Profiling information included
- Revali logs enabled
- Useful for performance analysis

<Callout type="tip">

Learn more about [build modes](/revali/cli/build#build-modes).

</Callout>

---

## Environment Variables

Pass environment variables to your Docker build using `--dart-define`:

```bash
dart run revali build --dart-define=API_KEY=secret --dart-define=PORT=3000
```

This generates a Dockerfile with build argument declarations (values must be provided via `--build-arg` when building):

<CodeFile name="Dockerfile">

```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN rm pubspec_overrides.yaml || true

RUN dart pub get

# Build arguments from --dart-define (values provided via --build-arg at build time)
ARG API_KEY
ARG PORT

RUN dart run revali build --release --type constructs --recompile

# Pass to compilation
RUN dart compile exe .revali/server/server.dart -o /app/server \
  -DAPI_KEY=$API_KEY \
  -DPORT=$PORT

FROM alpine:latest

RUN apk add --no-cache libc6-compat ca-certificates

COPY --from=build /app/server /app/bin/server

CMD ["/app/bin/server"]
```

</CodeFile>

### Providing Values at Build Time

Provide build argument values when building the Docker image:

```bash
docker build \
  --build-arg API_KEY=production_key \
  --build-arg PORT=8080 \
  -f .revali/build/Dockerfile \
  -t my-app .
```

<Callout type="tip">

Learn more about [environment variables](/revali/app-configuration/env-vars).

</Callout>

---

## Building Docker Images

### Basic Build

Build an image from the generated Dockerfile:

```bash
docker build -f .revali/build/Dockerfile -t my-app:latest .
```

### Tagged Build

Tag your image for versioning:

```bash
docker build -f .revali/build/Dockerfile -t my-app:v1.0.0 .
```

### Multi-Platform Build

Build for multiple architectures:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f .revali/build/Dockerfile \
  -t my-app:latest .
```

## Cross-Compiling

By default, Revali Docker compiles your server *inside* the Docker build (the multi-stage `dart:stable` build shown above). If you'd rather compile once on the host — no container pull, no `pub get` inside Docker — add a [`build:` section](/revali/cli/build#compiling-a-native-executable) to your `revali.yaml`:

<CodeFile name="revali.yaml">

```yaml
build:
  target_os: linux
  target_arch: [x64, arm64]
```

</CodeFile>

`revali build` will compile the server directly via `dart compile exe --target-os --target-arch` — cross-compiling to Linux works from any host OS (macOS, Windows, or Linux), no extra toolchain required. Revali Docker then generates a minimal single-stage Dockerfile instead:

```dockerfile
FROM alpine:latest

RUN apk add --no-cache libc6-compat ca-certificates

# single arch:
COPY .revali/build/server-amd64 /app/bin/server
# multiple arches (picks the right one via buildx's $TARGETARCH):
# ARG TARGETARCH
# COPY .revali/build/server-${TARGETARCH} /app/bin/server
RUN chmod +x /app/bin/server

CMD ["/app/bin/server"]
```

When `target_arch` lists more than one architecture, the `ARG TARGETARCH` form is used automatically — the existing [Multi-Platform Build](#multi-platform-build) `docker buildx build --platform ...` command above still works unchanged, now backed by fast native host compiles instead of a QEMU-emulated compile inside the container for each target platform.

<Callout type="caution">

This only compiles the Dart server itself. If your app depends on native (FFI) libraries, those still need to be built for the target platform separately — compiling for Linux from macOS doesn't cross-compile any bundled native `.so`/`.dylib` files.

</Callout>

### `.dockerignore`

If you exclude `.revali/` in your `.dockerignore` (recommended below, since it holds dev-time artifacts you don't want in your build context), you need to explicitly re-include `.revali/build/` — otherwise the `COPY` above can't find the compiled binary. Docker's `!negation` pattern **cannot** re-include a path whose parent directory was itself excluded, so exclude `.revali/`'s children individually instead of the directory itself:

<CodeFile name=".dockerignore">

```text
.revali/*
!.revali/build
```

</CodeFile>

### `--dart-define` values

Without cross-compiling, dart-defines are deferred to `docker build --build-arg` at image-build time (see [Environment Variables](#environment-variables) above). With cross-compiling, they're baked into the executable directly at `revali build` time using their real resolved values, since there's no container build step left to defer them to.

### Build with Custom Arguments

Provide build arguments:

```bash
docker build \
  --build-arg API_KEY=my_key \
  --build-arg DATABASE_URL=postgres://... \
  -f .revali/build/Dockerfile \
  -t my-app .
```

---

## Running Docker Containers

### Basic Run

Start your container:

```bash
docker run -p 8080:8080 my-app
```

### With Environment Variables

Pass runtime environment variables:

```bash
docker run \
  -e PORT=3000 \
  -e LOG_LEVEL=debug \
  -p 3000:3000 \
  my-app
```

### Detached Mode

Run in the background:

```bash
docker run -d -p 8080:8080 --name my-app-container my-app
```

### With Volume Mounts

Mount persistent storage:

```bash
docker run \
  -p 8080:8080 \
  -v $(pwd)/data:/app/data \
  my-app
```

---

## Docker Compose

For more complex deployments, use Docker Compose:

<CodeFile name="docker-compose.yml">

```yaml
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: .revali/build/Dockerfile
      args:
        API_KEY: ${API_KEY}
        DATABASE_URL: ${DATABASE_URL}
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - LOG_LEVEL=info
    restart: unless-stopped
    networks:
      - app-network

  database:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:

volumes:
  postgres-data:
```

</CodeFile>

Run with Docker Compose:

```bash
docker-compose up -d
```

---

## Image Optimization

### Best Practices

#### Use .dockerignore

Create a `.dockerignore` file to exclude unnecessary files:

<CodeFile name=".dockerignore">

```text
.git/
.github/
.dart_tool/
.revali/
build/
*.md
LICENSE
.gitignore
.env
node_modules/
doc-site/
examples/
test/
```

</CodeFile>

## Deployment

Once you have your Docker image, deploy it to your preferred platform:

### Popular Platforms

1. **[Fly.io](/constructs/revali_docker/deploy/fly-io)** - Global deployment with automatic scaling
2. **[DigitalOcean App Platform](https://www.digitalocean.com/products/app-platform/)** - Managed container hosting
3. **[Heroku](https://www.heroku.com/)** - Simple container deployment
4. **[Railway](https://railway.app/)** - Easy deployment with auto-scaling
5. **[Render](https://render.com/)** - Developer-friendly container platform

<Callout type="tip">

See the [deployment guides](/constructs/revali_docker/deploy) for platform-specific instructions.

</Callout>

---

## What's Next?

- **[Installation](/constructs/revali_docker/installation)** - Set up Revali Docker
- **[Deploy to Fly.io](/constructs/revali_docker/deploy/fly-io)** - Deploy your container
- **[Deployment Overview](/constructs/revali_docker/deploy)** - Explore deployment options
