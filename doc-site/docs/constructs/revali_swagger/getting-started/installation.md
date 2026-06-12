---
title: Installation
sidebar_position: 0
description: Add revali_swagger to your Revali project
---

# Installation

Revali Swagger is split across two packages:

| Package                      | Purpose                                              | Where              |
| ---------------------------- | ---------------------------------------------------- | ------------------ |
| `revali_swagger_annotations` | Runtime annotations (`@ApiTag`, `@ApiSummary`, etc.) | `dependencies`     |
| `revali_swagger`             | OpenAPI spec generator (the construct itself)        | `dev_dependencies` |

## Add the Packages

```bash
dart pub add revali_swagger_annotations
dart pub add --dev revali_swagger
```

Your `pubspec.yaml` should look like this:

```yaml title="pubspec.yaml"
dependencies:
  revali_swagger_annotations: ^1.0.0

dev_dependencies:
  revali_swagger: ^1.0.0
```

## Register the Construct

Add `revali_swagger` to your `revali.yaml` constructs list:

```yaml title="revali.yaml"
constructs:
  - package: revali_swagger
    path: lib/swagger.dart
```

That's all that's needed for a working spec. Configuration options are covered in [Configuration](./configuration).

## Run the Generator

```bash
dart run revali dev
```

The spec is written to:

```txt
.revali/
└── revali_swagger/
    ├── swagger.yaml
    └── swagger.json
```

:::tip
Commit `.revali/revali_swagger/swagger.yaml` and `.revali/revali_swagger/swagger.json` to version control if you want your spec available in CI without re-running `revali dev`.
:::

## Verify the Output

Open `.revali/revali_swagger/swagger.yaml` or `.revali/revali_swagger/swagger.json`. You should see your API paths listed under the `paths` key, with schemas for any complex types under `components/schemas`.

If a type could not be resolved, a warning is printed to stderr:

```txt
[revali_swagger] Warning: cannot infer schema for type 'Duration'.
Use @ApiType to specify the schema explicitly.
```

See [Type Inference](../type-inference) for guidance on resolving these warnings.
