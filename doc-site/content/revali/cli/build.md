---
title: revali build
description: Generate the server and run build constructs for deployment
---

`revali build` prepares your app for deployment. It runs in two phases:

1. **Constructs.** It regenerates the server into `.revali/server/` and runs your other constructs, such as `revali_client`.
2. **Build.** It runs [build constructs](/constructs#build-constructs), such as [`revali_docker`](/constructs/revali_docker), which write their output to `.revali/build/`. If `revali.yaml` has a [`build:` section](#compiling-a-native-executable), this phase also compiles a native executable.

```bash
dart run revali build
```

Without a build construct and without a `build:` section, the command only regenerates the server.

## Options

| Flag | Default | Description |
| --- | --- | --- |
| `--release` / `--profile` | `--release` | Build mode. See [Build Modes](#build-modes). |
| `--flavor`, `-f <name>` | none | Selects the [`@App(flavor:)`](/revali/app-configuration/create-an-app#flavors) to build. Case-sensitive. |
| `--dart-define`, `-D <KEY=value>` | none | Compile-time constant. Repeatable. |
| `--dart-define-from-file <path>` | none | A file of `KEY=value` pairs, passed as constants. Repeatable. |
| `--type <constructs\|build>` | both phases | Runs one phase only. `constructs` generates without building. `build` runs only the build constructs. |
| `--recompile` | off | Recompiles the construct kernel. Use it after changing a local construct. |

## Build Modes

| Mode | Flag | Effect |
| --- | --- | --- |
| Release (default) | `--release` | Production build. Revali's own logging is off, and error responses don't include `__DEBUG__` details. |
| Profile | `--profile` | Same as release, but Revali's logger stays on. |

Your code can check the mode with `kReleaseMode` and `kProfileMode` from `revali_router`.

## Compiling a Native Executable

When `revali.yaml` has a `build:` section, `revali build` also compiles the server with `dart compile exe`:

<CodeFile name="revali.yaml">

```yaml
build:
  target_os: linux            # optional, defaults to the host OS
  target_arch: [x64, arm64]   # optional, defaults to the host architecture
  strip_debug_info: true      # optional, default false
```

</CodeFile>

| Field | Default | Description |
| --- | --- | --- |
| `target_os` | host OS | `linux`, `macos` or `windows`. Any host can build for `linux`. Building for `macos` or `windows` has to run on that OS. |
| `target_arch` | host architecture | One architecture or a list of them. Each one produces its own executable. |
| `strip_debug_info` | `false` | Writes the debug information to a separate file (`dart compile exe -S`), which makes the binary smaller. |

- The section only has to exist. An empty `build:` compiles for the host OS and architecture.
- Executables are written to `.dart_tool/revali/build_artifacts/server-<os>-<arch>`.
- Build constructs that package an executable, such as [Revali Docker](/constructs/revali_docker#cross-compiling), use it instead of compiling their own.
- `--dart-define` values are compiled into the executable.

Without a `build:` section, nothing is compiled. The build constructs do the whole job.
