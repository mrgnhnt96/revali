# Revali Client Gen

A [Revali](https://pub.dev/packages/revali) construct that generates a typed Dart client package from your server's routes. The generated code depends on [`revali_client`][revali-client].

## Installation

In the Revali server project:

```bash
dart pub add revali_client
dart pub add --dev revali_client_gen
```

Run `dart run revali dev`. The client package is written to `.revali/revali_client/`. Options (`package_name`, `server_name`, `scheme`, `integrations`) go under `constructs:` in `revali.yaml`.

## Documentation

[docs.revali.dev/constructs/revali_client](https://docs.revali.dev/constructs/revali_client)

[revali-client]: https://pub.dev/packages/revali_client
