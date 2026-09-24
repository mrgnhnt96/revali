---
title: Build Constructs
description: Generic versus build constructs, and how to write a BuildConstruct with preBuild and postBuild hooks
---

A build construct generates deployment artifacts (a Dockerfile, a manifest, a deploy script) and runs only during `revali build`. Everything else, including anything the app needs during development, belongs in a generic construct.

## Generic vs build constructs

| | Generic | Build |
| --- | --- | --- |
| `construct.yaml` | `is_build` omitted or `false` | `is_build: true` |
| Entrypoint returns | `Construct` | `BuildConstruct` |
| `generate` receives | `RevaliContext` (`mode`, `flavor`) | `RevaliBuildContext` (adds `defines`, `compiledExecutables`) |
| Runs during | `revali dev` and `revali build` | `revali build` only |
| Output | `.revali/<name>/` | `.revali/build/`, shared with every other build construct |

Build constructs share one output directory, so give your files distinctive names.

## Writing one

<CodeFile name="construct.yaml">

```yaml
constructs:
  - name: my_deploy
    path: my_deploy.dart
    method: myDeployConstruct
    is_build: true
```

</CodeFile>

`BuildConstruct` is a `base` class, so your subclass must be `base`, `final` or `sealed`:

<CodeFile name="lib/my_deploy.dart">

```dart
import 'package:revali_construct/revali_construct.dart';

BuildConstruct myDeployConstruct([ConstructOptions? options]) {
  return const MyDeployConstruct();
}

final class MyDeployConstruct extends BuildConstruct {
  const MyDeployConstruct();

  @override
  Future<void> preBuild(RevaliBuildContext context, MetaServer server) async {
    // e.g. check that a required CLI is installed
  }

  @override
  BuildDirectory generate(RevaliBuildContext context, MetaServer server) {
    return BuildDirectory(
      files: [
        AnyFile(
          basename: 'deploy',
          extension: 'sh',
          content: 'echo "deploying ${context.mode.name} build"',
        ),
      ],
    );
  }

  @override
  Future<void> postBuild(RevaliBuildContext context, MetaServer server) async {
    // e.g. push the image
  }
}
```

</CodeFile>

## What `revali build` does, in order

1. Generates the server and all generic constructs.
2. If `revali.yaml` has a [`build:` section](/revali/cli/build#compiling-a-native-executable), compiles the server to native executables and exposes them as `context.compiledExecutables` (each with `path`, `targetArch` and an optional `debugInfoPath`).
3. Calls `preBuild` on every build construct.
4. Calls `generate` on every build construct and writes the files to `.revali/build/`.
5. Calls `postBuild` on every build construct.

`preBuild` and `postBuild` default to doing nothing. `context.defines` holds the `--dart-define` values passed to `revali build`.

A failure in one build construct's `generate` is logged and does not stop the others.
