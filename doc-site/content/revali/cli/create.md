---
title: revali create
description: Scaffold controllers, apps, lifecycle components, observers and pipes.
---

`revali create` writes a starter file for a Revali building block, already in
the right directory and following the naming rules.

```bash
dart run revali create                  # interactive menu
dart run revali create controller -n users
```

## Subcommands

| Subcommand | Option | Writes |
| --- | --- | --- |
| `controller` | `-n, --name` | `routes/controllers/<name>_controller.dart` |
| `app` | `-n, --flavor` | `routes/apps/<flavor>_app.dart` |
| `lifecycle-component` (aliases `lc`, `lifecycle`, `component`) | `-n, --name` | `lib/components/lifecycle_components/<name>.dart` |
| `observer` | `-n, --name` | `lib/components/observers/<name>_observer.dart` |
| `pipe` | `-r, --return-type`, `-i, --input-type` | `lib/components/pipes/<return_type>_pipe.dart` |

Every subcommand prompts for a missing option and accepts `-f, --force` to
overwrite an existing file.

## Change where files go

Override any default directory under `server.create_paths` in `revali.yaml`.
A value is a path string or a list of segments:

<CodeFile name="revali.yaml">

```yaml
server:
  create_paths:
    controller: routes/api
    app: [routes, apps]
    lifecycle_component: lib/components
    observer: lib/components
    pipe: lib/pipes
```

</CodeFile>

Controllers and apps must stay under `routes/` for Revali to find them.
