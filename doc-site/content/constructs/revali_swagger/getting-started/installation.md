---
title: Installation
description: Add revali_swagger to your Revali project
---

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

<CodeFile name="pubspec.yaml">

```yaml
dependencies:
  revali_swagger_annotations: ^1.0.0

dev_dependencies:
  revali_swagger: ^1.0.0
```

</CodeFile>

## Register the Construct

Add `revali_swagger` to your `revali.yaml` constructs list:

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_swagger
```

</CodeFile>

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

<Callout type="tip">

Commit `.revali/revali_swagger/swagger.yaml` and `.revali/revali_swagger/swagger.json` to version control if you want your spec available in CI without re-running `revali dev`.

</Callout>

## Verify the Output

Open `.revali/revali_swagger/swagger.yaml` or `.revali/revali_swagger/swagger.json`. You should see your API paths listed under the `paths` key, with schemas for any complex types under `components/schemas`.

If a type could not be resolved, a warning is printed to stderr:

```txt
[revali_swagger] Warning: cannot infer schema for type 'Duration'.
Use @ApiType to specify the schema explicitly.
```

See [Type Inference](../type-inference) for guidance on resolving these warnings.
