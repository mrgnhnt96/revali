---
title: Overview
description: What constructs are, how Revali finds them, and how to configure them in revali.yaml
---

A construct is a Dart package that generates code or files from your routes. Revali generates the server itself; constructs generate everything else: a typed client, an OpenAPI spec, a Dockerfile, or whatever you write yourself.

## Official constructs

| Construct | Generates | Type | Output |
| --- | --- | --- | --- |
| [revali_client](/constructs/revali_client) | A typed Dart client package | Generic | `.revali/revali_client/` |
| [revali_swagger](/constructs/revali_swagger) | `swagger.yaml` / `swagger.json` (OpenAPI 3.0.3) | Generic | `.revali/revali_swagger/` |
| [revali_docker](/constructs/revali_docker) | A `Dockerfile` for the server | Build | `.revali/build/` |

## Server Generation

Server generation is built into the `revali` package. There is no construct to install or configure for it. `revali dev` and `revali build` always generate the server into `.revali/server/`. See [Revali Server](/constructs/revali_server) for the annotations it reads.

## Installing a construct

Add the construct package to your server's **`dev_dependencies`**. Revali only looks for constructs there: it reads each dev dependency and treats any package with a `construct.yaml` at its root as a construct. A construct listed under `dependencies` is ignored.

```bash
dart pub add --dev revali_swagger
```

That is enough. Unless the construct is opt-in, it runs on the next `dart run revali dev` with no `revali.yaml` entry.

## Construct types

| Type | Runs during | Output directory |
| --- | --- | --- |
| Generic | `revali dev` and `revali build` | `.revali/<construct name>/` |
| Build | `revali build` only | `.revali/build/`, shared by every build construct |

```tree
.revali/
├── server/           # built into revali
├── revali_client/    # generic construct
├── revali_swagger/   # generic construct
└── build/            # all build constructs (e.g. Dockerfile)
```

If two packages ship a construct with the same name, each one's output is nested under its package name instead: `.revali/<package>/<construct name>/`.

### Build Constructs

Build constructs generate deployment artifacts. They run only during [`revali build`](/revali/cli/build), with `preBuild` and `postBuild` hooks around generation. A project can use any number of them. [revali_docker](/constructs/revali_docker) is a build construct.

## Configuring constructs

Each entry under `constructs:` in `revali.yaml` matches a construct by `name`:

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_client
    options:
      package_name: my_api_client
  - name: revali_swagger
    enabled: false
```

</CodeFile>

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `name` | `String` | required | The construct's name from its `construct.yaml`, e.g. `revali_client`. |
| `package` | `String` | none | The package that provides it. Only needed when two packages ship constructs with the same `name`. |
| `enabled` | `bool` | unset | `false` disables the construct. `true` is required to turn on an opt-in construct. |
| `options` | `Map` | `{}` | Passed to the construct as-is. Each construct documents its own keys. |

An **opt-in** construct (one whose `construct.yaml` sets `opt_in: true`) is skipped until an entry sets `enabled: true`. None of the official constructs are opt-in.

See [revali.yaml](/revali/revali-configuration) for the rest of the file.

## Writing your own

A construct is an ordinary Dart package with a `construct.yaml` and an entrypoint function. See [Create Constructs](/create-constructs).
