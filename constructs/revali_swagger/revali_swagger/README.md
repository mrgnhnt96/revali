# Revali Swagger

A [Revali](https://pub.dev/packages/revali) construct that generates an OpenAPI 3.0.3 spec from your routes, parameters and return types.

## Installation

```bash
dart pub add --dev revali_swagger
dart pub add revali_swagger_annotations # optional
```

Run `dart run revali dev`. The spec is written to `.revali/revali_swagger/swagger.yaml` and `swagger.json`. Set `title`, `version` and `description` under `constructs:` in `revali.yaml`, and use [`revali_swagger_annotations`][revali-swagger-annotations] for summaries, tags, responses and schema overrides.

## Documentation

[docs.revali.dev/constructs/revali_swagger](https://docs.revali.dev/constructs/revali_swagger)

[revali-swagger-annotations]: https://pub.dev/packages/revali_swagger_annotations
