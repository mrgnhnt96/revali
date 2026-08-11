---
title: revali build
description: Prepare your application for deployment
---

The `revali build` command prepares your application for deployment by running [Build Constructs](/constructs#build-constructs). These constructs generate optimized code, assets, and other files needed for production deployment.

## What Does `revali build` Do?

When you run `revali build`, Revali:

1. **Analyzes Your Code**: Scans your project for build constructs
2. **Runs Build Constructs**: Executes all registered build constructs
3. **Generates Assets**: Creates deployment-ready files and code
4. **Optimizes Output**: Applies performance optimizations
5. **Prepares for Deployment**: Creates production-ready artifacts

## Basic Usage

```bash
dart run revali build
```

This runs the build process in Release mode with full optimizations.

## Options

| Flag | Description |
| --- | --- |
| `--release` / `--profile` | Build mode (see [Build Modes](#build-modes) below). Release is the default. |
| `--flavor`, `-f <name>` | The flavor to use for the app (case-sensitive). |
| `--recompile` | Re-compiles the construct kernel. Needed to sync changes for a local construct. |
| `--dart-define`, `-D <KEY=value>` | Additional key-value pairs available as compile-time constants. Repeatable. |
| `--dart-define-from-file <path>` | A file (e.g. `.env`) containing additional key-value pairs available as constants. Repeatable. |

## Build Modes

Revali supports two build modes, each optimized for different deployment scenarios:

### Release Mode (Default)

Release mode generates fully optimized code for production deployment:

```bash
dart run revali build --release
```

**Features:**

- ✅ Full performance optimizations
- ✅ Minified code output
- ✅ Production-ready assets
- ✅ Optimized bundle sizes
- ❌ No debug information

**When to use:**

- Production deployments
- Performance-critical applications
- Final release builds

### Profile Mode

Profile mode generates optimized code while preserving some debugging capabilities:

```bash
dart run revali build --profile
```

**Features:**

- ✅ Performance optimizations
- ✅ Revali logs enabled
- ✅ Debug information preserved
- ✅ Production-ready output
- ✅ Profiling capabilities

**When to use:**

- Performance testing
- Production debugging
- Performance optimization analysis

## Build Constructs

Build constructs are specialized packages that generate deployment artifacts:

### Common Build Constructs

- **Docker Constructs**: Generate Dockerfiles and container configurations
- **Asset Constructs**: Bundle static assets and resources
- **Code Constructs**: Generate optimized server code
- **Deployment Constructs**: Create deployment scripts and configurations

### Example Build Output

```tree
.revali/
├── build/
│   ├── Dockerfile
│   ├── assets/
│   │   ├── static/
│   │   └── templates/
│   └── deployment/
│       ├── scripts/
│       └── configs/
```

## Build Process

### 1. Pre-Build Analysis

```bash
dart run revali build
```

The build process first analyzes your project:

- Scans for build constructs
- Validates configuration
- Checks dependencies
- Prepares build environment

### 2. Construct Execution

Each build construct runs in sequence:

- **Docker Construct**: Generates containerization files
- **Asset Construct**: Bundles static resources
- **Code Construct**: Optimizes server code
- **Deployment Construct**: Creates deployment scripts

### 3. Post-Build Validation

After all constructs complete:

- Validates generated files
- Checks for build errors
- Reports build statistics
- Prepares deployment artifacts

## Build Configuration

### Compiling a Native Executable

Adding a `build:` section to your `revali.yaml` tells `revali build` to compile your server into a native executable via `dart compile exe`, in addition to running your build constructs:

<CodeFile name="revali.yaml">

```yaml
build:
  target_os: linux            # optional, defaults to the host OS
  target_arch: [x64, arm64]   # optional, defaults to the host architecture
  strip_debug_info: true      # optional, default false
```

</CodeFile>

Its mere presence is the signal — every field is optional and falls back to the host machine's own OS/architecture. `dart compile exe` can cross-compile to Linux from any host OS (macOS, Windows, or Linux) with no extra toolchain, added in Dart 3.8. Compiling for `macos` or `windows` targets still requires running `revali build` natively on that OS — there is no cross-compiling *to* those targets.

`target_arch` accepts a list so you can compile once per architecture in a single `revali build` run (useful for multi-platform container images — see [Revali Docker](/constructs/revali_docker#cross-compiling)). `strip_debug_info` removes the AOT debug information from the executable and saves it separately (`dart compile exe -S`), producing a smaller binary at the cost of needing that separate file to symbolicate a crash later.

Build constructs that know how to package a compiled executable (like [Revali Docker](/constructs/revali_docker)) will automatically use it instead of compiling it themselves. Without a `build:` section, `revali build` behaves exactly as it does today — it only runs build constructs, and doesn't compile anything on its own.

`--dart-define` values are baked into the compiled executable directly, using their real resolved values — unlike a construct like Revali Docker's default (non-compiled) Dockerfile, which defers dart-defines to `docker build --build-arg` at image-build time.

## Build Artifacts

### Generated Files

Build constructs can generate various deployment artifacts:

**Assets:**

- Static files bundled and optimized
- Templates processed and minified
- Resources compressed and cached

**Deployment Scripts:**

- Startup scripts for different environments
- Configuration files for deployment platforms
