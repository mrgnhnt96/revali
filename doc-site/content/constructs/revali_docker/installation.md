---
title: Installation
description: Learn how to install Revali Docker and its dependencies
---

Revali Docker is an optional build construct — add it as a dev dependency to opt in:

```bash
dart pub add revali_docker --dev
```

Or manually add to `pubspec.yaml`:

<CodeFile name="pubspec.yaml">

```yaml
dev_dependencies:
  revali_docker: <latest>
```

</CodeFile>

Once added, `dart run revali build` generates a `Dockerfile` at `.revali/build/Dockerfile` — no further configuration required. See [Revali Server installation](/constructs/revali_server/getting-started/installation) for setting up the server itself.
