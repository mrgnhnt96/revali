---
title: Overview
description: Generate production-ready Dockerfiles for Revali applications
sidebar_position: 0
---

# Revali Docker

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

:::note
While designed for [Revali Server](/constructs/revali_server/overview), Revali Docker can generate Dockerfiles for any Revali application.
:::

---

## Quick Start

Generate a Dockerfile for your project:

```bash
dart run revali build
```

The generated `Dockerfile` will be created at:

```
.revali/build/docker/Dockerfile
```

Build and run your Docker image:

```bash
# Build the image
docker build -f .revali/build/docker/Dockerfile -t my-app .

# Run the container
docker run -p 8080:8080 my-app
```

---

## Generated Dockerfile Structure

Here's an example of a generated Dockerfile with explanations:

```dockerfile title=".revali/build/docker/Dockerfile"
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

:::tip
Learn more about [build modes](/revali/cli/build#build-modes).
:::

---

## Environment Variables

Pass environment variables to your Docker build using `--dart-define`:

```bash
dart run revali build --dart-define=API_KEY=secret --dart-define=PORT=3000
```

This generates a Dockerfile with build arguments:

```dockerfile title="Dockerfile"
FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN rm pubspec_overrides.yaml || true

RUN dart pub get

# Build arguments from --dart-define
ARG API_KEY=secret
ARG PORT=3000

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

### Overriding at Build Time

You can override build arguments when building the Docker image:

```bash
docker build \
  --build-arg API_KEY=production_key \
  --build-arg PORT=8080 \
  -f .revali/build/docker/Dockerfile \
  -t my-app .
```

:::tip
Learn more about [environment variables](/revali/app-configuration/env-vars).
:::

---

## Building Docker Images

### Basic Build

Build an image from the generated Dockerfile:

```bash
docker build -f .revali/build/docker/Dockerfile -t my-app:latest .
```

### Tagged Build

Tag your image for versioning:

```bash
docker build -f .revali/build/docker/Dockerfile -t my-app:v1.0.0 .
```

### Multi-Platform Build

Build for multiple architectures:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f .revali/build/docker/Dockerfile \
  -t my-app:latest .
```

### Build with Custom Arguments

Override build arguments:

```bash
docker build \
  --build-arg API_KEY=my_key \
  --build-arg DATABASE_URL=postgres://... \
  -f .revali/build/docker/Dockerfile \
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

```yaml title="docker-compose.yml"
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: .revali/build/docker/Dockerfile
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

Run with Docker Compose:

```bash
docker-compose up -d
```

---

## Image Optimization

### Best Practices

#### Use .dockerignore

Create a `.dockerignore` file to exclude unnecessary files:

```text title=".dockerignore"
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

## Deployment

Once you have your Docker image, deploy it to your preferred platform:

### Popular Platforms

1. **[Fly.io](/constructs/revali_docker/deploy/fly.io)** - Global deployment with automatic scaling
2. **[DigitalOcean App Platform](https://www.digitalocean.com/products/app-platform/)** - Managed container hosting
3. **[Heroku](https://www.heroku.com/)** - Simple container deployment
4. **[Railway](https://railway.app/)** - Easy deployment with auto-scaling
5. **[Render](https://render.com/)** - Developer-friendly container platform

:::tip
See the [deployment guides](/constructs/revali_docker/deploy/overview) for platform-specific instructions.
:::

---

## What's Next?

- **[Installation](/constructs/revali_docker/installation)** - Set up Revali Docker
- **[Deploy to Fly.io](/constructs/revali_docker/deploy/fly.io)** - Deploy your container
- **[Deployment Overview](/constructs/revali_docker/deploy/overview)** - Explore deployment options
