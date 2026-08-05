---
title: revali doctor
sidebar_position: 3
description: Diagnose SDK, construct, kernel cache, and generated-output issues
---

# The Doctor Command

The `revali doctor` command checks your SDK, resolved constructs, construct kernel cache, and generated output freshness — useful when `revali dev`/`revali build` are behaving unexpectedly.

## Basic Usage

```bash
dart run revali doctor
```

Example output:

```text
✓ [ok] sdk: 3.12.2
✓ [ok] project_root: /path/to/your/app
✓ [ok] revali_packages: revali, revali_annotations, revali_core, revali_construct, revali_router
✓ [ok] constructs: revali_server:revali_server
✓ [ok] kernel_cache: hit 8f2a1c...
✓ [ok] local_kernel: fresh
✓ [ok] generated_outputs: up to date vs routes/ and lib/
✓ [ok] routes_manifest: .revali/server/routes.json
✓ [ok] exception_catchers: no thrown types scanned
```

## Options

| Flag | Description |
| --- | --- |
| `--json` | Print a structured JSON report (`{ ok, checks: [...] }`) instead of the human-readable list. |

## What It Checks

| Check | Meaning when it warns/errors |
| --- | --- |
| `sdk` | The Dart SDK version currently running `revali doctor`. |
| `project_root` | Whether the project root could be resolved. An error here stops all further checks. |
| `package_config` | Whether `.dart_tool/package_config.json` exists — run `dart pub get` if not. |
| `revali_packages` | Which `revali*` packages are resolved for this project. Empty is a warning. |
| `constructs` | Constructs resolved from your dependencies. Empty is a warning. |
| `kernel_cache` | Whether the shared construct-kernel cache has an entry for this construct set + SDK. A miss just means the next build recompiles once. |
| `local_kernel` | Whether the local construct kernel (`.revali/revali.dart.dill`) exists and is fresh against construct/`revali_*` sources. |
| `generated_outputs` | Whether `.revali/server/server.dart` is up to date against `routes/` and `lib/`. Stale means re-run `revali dev --generate-only`. |
| `routes_manifest` | Whether `.revali/server/routes.json` exists (see [`revali routes`](/revali/cli/routes)). |
| `exception_catchers` | Best-effort scan for thrown types under `routes/`/`lib/` that may need a matching `ExceptionCatcher` registered. Info-only, never fails the check. |

Only `project_root` and `package_config` errors are treated as hard failures (non-zero exit code) — everything else is advisory.

## Next Steps

- **[The Routes Command](/revali/cli/routes)**: List generated routes
- **[The Dev Command](/revali/cli/dev)**: Start the development server
