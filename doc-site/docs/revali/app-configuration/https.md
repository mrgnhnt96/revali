---
sidebar_position: 6
description: Run your server over HTTPS using a local certificate
---

# HTTPS in Development

Revali can bind an `HttpServer` with TLS via `AppConfig.secure`, backed by `dart:io`'s `SecurityContext`. This is most useful in development when a client (a physical mobile device, a browser enforcing secure-context APIs, etc.) requires HTTPS even against `localhost`.

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

This produces two files — commit `certificates/` to `.gitignore`, since these are local-machine credentials, not something to ship or share.

## Configure `AppConfig.secure`

Use the `AppConfig.secure` named constructor (instead of the default `AppConfig(...)`), and build a `SecurityContext` from the generated files:

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

Run it the same way as always:

```bash
dart run revali dev
```

Your server is now reachable at `https://localhost:8443/api/`.

## Available Options

`AppConfig.secure` accepts everything the default constructor does (`host`, `port`, `prefix`, `workers`, `backlog`), plus:

| Parameter | Description |
| --- | --- |
| `securityContext` (required) | The `dart:io` `SecurityContext` holding the certificate chain and private key. |
| `requestClientCertificate` | Whether to request a client certificate (mutual TLS). Defaults to `false`. |

## Connecting from a Physical Device

If you need a *different* device on your network to trust the certificate (not just this machine's browser), install the mkcert root CA on that device too — mkcert prints the CA's location with `mkcert -CAROOT`. Alternatively, generate the certificate for your machine's LAN IP instead of `localhost` (`mkcert -key-file ... -cert-file ... 192.168.1.50`) so the hostname the device connects to matches what's on the certificate.

## Next Steps

- **[Create an App](/revali/app-configuration/create-an-app)**: Basic `AppConfig` setup
- **[App Configuration Overview](/revali/app-configuration/overview)**: `AppConfig` fundamentals
