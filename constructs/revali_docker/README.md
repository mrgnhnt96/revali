# Revali Docker

A [Revali](https://pub.dev/packages/revali) build construct that writes a multi-stage `Dockerfile` for your server to `.revali/build/Dockerfile` on every `revali build`.

## Installation

```bash
dart pub add --dev revali_docker
```

No configuration. Use `AppConfig.fromEnv()` in your app so the server listens on `0.0.0.0` inside the container.

## Usage

```bash
dart run revali build
docker build -f .revali/build/Dockerfile -t my-app .
docker run -p 8080:8080 my-app
```

## Documentation

[docs.revali.dev/constructs/revali_docker](https://docs.revali.dev/constructs/revali_docker)
