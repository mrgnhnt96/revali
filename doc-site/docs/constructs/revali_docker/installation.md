---
title: Installation
description: Learn how to install Revali Docker and its dependencies
sidebar_position: 1
---

# Installation

Revali Docker is an optional build construct — add it as a dev dependency to opt in:

```bash
dart pub add revali_docker --dev
```

Or manually add to `pubspec.yaml`:

```yaml title="pubspec.yaml"
dev_dependencies:
  revali_docker: <latest>
```

Once added, `dart run revali build --type constructs` (or `buildAndConstructs`) generates a `Dockerfile` alongside your server code — no further configuration required. See [Revali Server installation](../revali_server/getting-started/installation.md) for setting up the server itself.
