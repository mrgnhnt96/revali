---
title: revali build
sidebar_position: 1
description: Prepare your application for deployment
---

# The Build Command

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
│   ├── docker/
│   │   ├── Dockerfile
│   │   └── docker-compose.yml
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
dart run revali build --verbose
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

### Custom Build Settings

You can configure build behavior in your `revali.yaml`:

```yaml title="revali.yaml"
build:
  mode: release
  output: .revali/build
  constructs:
    - docker
    - assets
    - deployment
  optimization:
    minify: true
    compress: true
    treeShake: true
```

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
