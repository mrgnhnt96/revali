# CHANGELOG

## 1.2.0 | 08.15.26

### Fixes

- Raise the `revali_construct` floor to `^3.0.0`. Nothing in this package changed; it is re-released so the published set still resolves. `revali_construct` is a new major this round, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 1.1.0 behind on `^2.4.0` would make it unresolvable alongside it.

## 1.1.0 | 08.05.26

### Features

- Automatically generate a minimal single-stage Dockerfile whenever `revali build` already compiled a native executable (via a `build:` section in `revali.yaml`), instead of the default multi-stage, compile-inside-Docker build. Supports multi-architecture images via `ARG TARGETARCH`. See [Cross-Compiling](https://www.revali.dev/constructs/revali_docker#cross-compiling).

## 1.0.0 | 08.04.26

### Features

- Extracted from `revali_server` into its own standalone build construct. Generates production-ready, multi-stage Dockerfiles for your Revali server — install it directly with `dart pub add revali_docker --dev`.
