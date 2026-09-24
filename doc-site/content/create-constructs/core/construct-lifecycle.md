---
title: Construct Lifecycle
description: How Revali discovers, compiles, caches and runs constructs, and when to pass --recompile
---

What happens between `dart run revali dev` and your construct's `generate` being called. Knowing this explains why an edit to a construct sometimes does not show up.

## 1. Discovery

Revali reads the server's `pubspec.yaml` and, for each **`dev_dependencies`** entry, looks for a `construct.yaml` next to that package's `pubspec.yaml`. Packages without one are skipped. Each listed construct's entrypoint (`lib/<path>`) must exist, or the run fails with `Failed to find the entrypoint for construct <name>`. The built-in server construct from `revali` is always added.

## 2. The construct runner

Revali writes a Dart program that imports every construct's entrypoint and compiles it to a kernel file:

```tree
.dart_tool/revali/
├── revali.dart          # generated runner: one ConstructMaker per construct
├── revali.dart.dill     # compiled runner
└── revali.assets.json   # cached construct configuration
```

Compiling is the slow part, so the kernel is reused between runs. It is rebuilt when:

- the set of constructs or their `construct.yaml` configuration changes, or
- any `.dart` file under a construct package's `lib/`, or under `lib/` of a path-dependency `revali` / `revali_*` package, is newer than the kernel.

Pass `--recompile` to `revali dev` or `revali build` to force a rebuild, for example after changing a dependency of your construct that is not itself a construct package:

```bash
dart run revali dev --recompile
```

## 3. Running

The runner analyzes the server into a `MetaServer`, then for each construct:

1. Reads its entry in `revali.yaml`. A construct with `enabled: false` is skipped, and so is an `opt_in` construct without `enabled: true`.
2. Calls your entrypoint function with the entry's `options`.
3. Calls `generate` and writes the returned files.

Output is written to a staging directory and swapped into `.revali/` after every construct has finished. Each construct's directory is replaced as a whole, so files you stopped returning disappear, and `.revali/build/` is replaced as a whole on every `revali build`. Directories in `.revali/` that no construct produced this run (other than `build/`) are removed.

An exception in a generic or build construct is logged and the run continues without that construct's output. An exception in server generation fails the run and leaves the previous `.revali/` untouched.

See [Debugging](/create-constructs/tips-and-tricks) to step through this in a debugger.
