# CHANGELOG

## 1.1.0 | 08.05.26

### Features

- Automatically generate a minimal single-stage Dockerfile whenever `revali build` already compiled a native executable (via a `build:` section in `revali.yaml`), instead of the default multi-stage, compile-inside-Docker build. Supports multi-architecture images via `ARG TARGETARCH`. See [Cross-Compiling](https://www.revali.dev/constructs/revali_docker/overview#cross-compiling).

## 1.0.0 | 08.04.26

### Features

- Extracted from `revali_server` into its own standalone build construct. Generates production-ready, multi-stage Dockerfiles for your Revali server — install it directly with `dart pub add revali_docker --dev`.
