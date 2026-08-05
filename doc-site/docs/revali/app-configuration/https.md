---
sidebar_position: 6
description: Run your server over HTTPS using a local certificate
---

# HTTPS in Development

Revali can bind an `HttpServer` with TLS, backed by `dart:io`'s `SecurityContext`. This is most useful in development when a client (a physical mobile device, a browser enforcing secure-context APIs, etc.) requires HTTPS even against `localhost`.

There are two ways to enable it — `--cert`/`--key` on `revali dev` (no code changes, the easiest path for local testing) or `AppConfig.secure` (programmatic, for when you need more control). Both need a certificate and key file, so start there either way.

## Generate a Local Certificate with mkcert

[mkcert](https://github.com/FiloSottile/mkcert) creates locally-trusted certificates without the browser warnings a self-signed cert would trigger.

```bash
# Install mkcert (macOS)
brew install mkcert

# Install the local CA into your system/browser trust stores (once per machine)
mkcert -install

# Generate a cert + key for localhost
mkcert -key-file certificates/localhost-key.pem -cert-file certificates/localhost.pem localhost 127.0.0.1 ::1
```

This produces two files — add `certificates/` to `.gitignore`, since these are local-machine credentials, not something to ship or share.

## Quick Start: `--cert` / `--key`

Pass the generated files directly to `revali dev` — no code changes needed, even if your `AppConfig` uses the plain (non-secure) constructor:

```bash
dart run revali dev --cert certificates/localhost.pem --key certificates/localhost-key.pem
```

Your server is now reachable over HTTPS at whatever host/port your `AppConfig` already specifies (e.g. `https://localhost:8080/api/`). `--cert` and `--key` must be passed together — providing only one is an error.

:::note
The startup log still prints `Serving at http://...` even when TLS is active — that message doesn't yet know about the connection scheme. The server itself is genuinely serving HTTPS; only the log line's `http://` is cosmetic.
:::

## Advanced: `AppConfig.secure`

Reach for `AppConfig.secure` instead of `--cert`/`--key` when you need to build the `SecurityContext` yourself — for example, loading a certificate from somewhere other than two PEM files, switching it conditionally based on `--flavor`, or requesting a client certificate for mutual TLS (`requestClientCertificate`, not available via the CLI flags).

```dart title="routes/main_app.dart"
import 'dart:io';

import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  MainApp()
      : super.secure(
          host: 'localhost',
          port: 8443,
          securityContext: SecurityContext()
            ..useCertificateChain('certificates/localhost.pem')
            ..usePrivateKey('certificates/localhost-key.pem'),
        );
}
```

:::note
`AppConfig.secure` isn't `const` — a `SecurityContext` wraps a native, mutable TLS context, so the constructor above can't be `const` either.
:::

Run it the same way as always, with no `--cert`/`--key` flags needed:

```bash
dart run revali dev
```

If both are present — an `AppConfig.secure` app *and* `--cert`/`--key` on the command line — the CLI flags win, since they're a more specific, explicit request for that particular run.

### Available Options

`AppConfig.secure` accepts everything the default constructor does (`host`, `port`, `prefix`, `workers`, `backlog`), plus:

| Parameter | Description |
| --- | --- |
| `securityContext` (required) | The `dart:io` `SecurityContext` holding the certificate chain and private key. |
| `requestClientCertificate` | Whether to request a client certificate (mutual TLS). Defaults to `false`. |

## Connecting from a Physical Device

If you need a *different* device on your network to trust the certificate (not just this machine's browser), install the mkcert root CA on that device too — mkcert prints the CA's location with `mkcert -CAROOT`. Alternatively, generate the certificate for your machine's LAN IP instead of `localhost` (`mkcert -key-file ... -cert-file ... 192.168.1.50`) so the hostname the device connects to matches what's on the certificate.

## Next Steps

- **[The Dev Command](/revali/cli/dev)**: Full `revali dev` flag reference
- **[Create an App](/revali/app-configuration/create-an-app)**: Basic `AppConfig` setup
- **[App Configuration Overview](/revali/app-configuration/overview)**: `AppConfig` fundamentals
