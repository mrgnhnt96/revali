---
title: Revali Configuration
description: Configure constructs, hot reload, native builds and scaffolding in revali.yaml
---

`revali.yaml` is an optional file in the package root, next to `pubspec.yaml`. It configures the CLI: which constructs run and with what options, what hot reload ignores, whether `revali build` compiles an executable, and where `revali create` writes new files. If the file doesn't exist, the CLI uses its defaults.

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_client
    options:
      package_name: my_api_client

hot_reload:
  exclude:
    - docs

build:
  target_os: linux
  target_arch: [x64, arm64]
```

</CodeFile>

| Key | Purpose | Reference |
| --- | --- | --- |
| `constructs` | Enable, disable and configure constructs | [below](#constructs) |
| `hot_reload.exclude` | Paths that don't trigger a reload in `revali dev` | [below](#hot-reload) |
| `build` | Compile a native executable in `revali build` | [`revali build`](/revali/cli/build#compiling-a-native-executable) |
| `server.create_paths` | Where `revali create` writes new files | [`revali create`](/revali/cli/create) |

## Constructs

Every construct in your dependencies runs by default, except opt-in constructs, which run only when you set `enabled: true`. Each entry is matched to a construct by `name`:

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_docker
    enabled: false        # turn a construct off
  - name: revali_swagger
    options:              # construct-specific settings
      title: My API
      version: 2.1.0
  - name: revali_client
    options:
      package_name: my_api_client
      scheme: https
```

</CodeFile>

| Field | Description |
| --- | --- |
| `name` | The construct's name, as declared in its package's `construct.yaml`. Required. |
| `enabled` | `false` turns the construct off. `true` turns on an opt-in construct. If omitted, the construct's own default applies. |
| `package` | The package that provides the construct. Only needed when two packages declare constructs with the same name. |
| `options` | A map passed to the construct. Each construct's page lists the options it accepts. |

If two packages declare a construct with the same name, add `package` to each entry. Without it, generation fails:

```yaml
constructs:
  - name: docs
    package: revali_swagger
  - name: docs
    package: my_custom_package
    enabled: false
```

## Hot Reload

`revali dev` reloads when any file in the package changes. It always ignores `.revali/`, `bin/`, `test/` and `tool/`. To ignore more, list the paths under `exclude`:

<CodeFile name="revali.yaml">

```yaml
hot_reload:
  exclude:
    - lib/generated   # relative to revali.yaml
    - docs
    - /tmp/cache      # absolute paths work too
```

</CodeFile>

Excluding a directory ignores every file inside it.
