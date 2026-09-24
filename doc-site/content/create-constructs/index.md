---
title: Overview
description: Write your own Revali construct to generate files from a server's routes
---

A construct is a Dart package that Revali runs during `revali dev` or `revali build`. It receives an analyzed model of the server (controllers, methods, parameters, types, apps) and returns files, which Revali writes under `.revali/`. `revali_client`, `revali_swagger` and `revali_docker` are all constructs. Write one when you want to generate something from your routes that they do not cover: a client in another language, route documentation, deployment manifests.

## What a construct package contains

```tree
my_construct/
├── construct.yaml          # registers the construct(s)
├── pubspec.yaml            # depends on revali_construct
└── lib/
    └── my_construct.dart   # top-level entrypoint function
```

The server project adds the package to its `dev_dependencies`. Revali discovers it by its `construct.yaml`, compiles it into the construct runner, and calls it on every run.

## Two kinds

| | Generic construct | Build construct |
| --- | --- | --- |
| Extends | `Construct` | `BuildConstruct` |
| `construct.yaml` | default | `is_build: true` |
| Runs during | `revali dev` and `revali build` | `revali build` only |
| Writes to | `.revali/<name>/` | `.revali/build/` (shared) |
| Hooks | none | `preBuild`, `postBuild` |
| Examples | `revali_client`, `revali_swagger` | `revali_docker` |

Server generation is part of `revali` itself and is not something you can replace with a construct.

## Guides

- [Getting Started](/create-constructs/getting-started): build, register and run a generic construct end to end.
- [Build Constructs](/create-constructs/core/build-construct): `is_build`, `BuildConstruct` and the build hooks.
- [Construct Lifecycle](/create-constructs/core/construct-lifecycle): discovery, caching and when to pass `--recompile`.
- [Debugging](/create-constructs/tips-and-tricks): step through your construct in a debugger.

For the user-facing side (installing constructs and configuring them in `revali.yaml`), see [Constructs](/constructs).
