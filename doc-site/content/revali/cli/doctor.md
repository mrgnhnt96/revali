---
title: revali doctor
description: Diagnose SDK, construct, kernel cache, and generated-output issues
---

`revali doctor` checks your project's setup. Run it when `revali dev` or `revali build` behaves unexpectedly. It checks the SDK, resolved packages and constructs, the construct kernel, and whether the generated output is up to date.

```bash
dart run revali doctor
```

```text
✓ [ok] sdk: 3.8.1
✓ [ok] project_root: /path/to/your/app
✓ [ok] revali_packages: revali, revali_annotations, revali_construct, revali_core, revali_router
✓ [ok] constructs: revali:revali_server
✓ [ok] kernel_cache: hit 8f2a1c...
✓ [ok] local_kernel: fresh
✓ [ok] generated_outputs: up to date vs routes/ and lib/
✓ [ok] routes_manifest: .revali/server/routes.json
✓ [ok] exception_catchers: no thrown types scanned
```

## Options

| Flag | Description |
| --- | --- |
| `--json` | Prints `{ "ok": bool, "checks": [{ "id", "status", "detail" }] }`. |

## Checks

| Check | If it warns or fails |
| --- | --- |
| `sdk` | Information only. Shows the Dart SDK version. |
| `project_root` | **Error.** No project root was found. Run the command inside your package. |
| `package_config` | **Error.** `.dart_tool/package_config.json` is missing. Run `dart pub get`. |
| `revali_packages` | No `revali*` packages resolved. Add `revali` (dev dependency) and `revali_router`. |
| `constructs` | No constructs resolved from your dependencies. |
| `kernel_cache` | Cache miss. The next run compiles the construct kernel once. |
| `local_kernel` | `.revali/revali.dart.dill` is missing or out of date. Run with `--recompile`. |
| `generated_outputs` | `.revali/server/server.dart` is missing or older than `routes/` or `lib/`. Run `dart run revali dev --generate-only`. |
| `routes_manifest` | `.revali/server/routes.json` is missing. Regenerate the server. |
| `exception_catchers` | Information only. Lists types thrown under `routes/` or `lib/` that might need an exception catcher. |

Only the two **Error** checks fail the command with exit code `1`. Every other check is advisory.
