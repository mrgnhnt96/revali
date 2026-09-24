---
title: HTTPS in Development
description: Serve HTTPS locally with --cert/--key or AppConfig.secure
---

Serve HTTPS when a client requires it even against a local server, such as a physical phone or a browser feature that needs a secure context. There are two ways to do it:

- `--cert` and `--key` on `revali dev` need no code changes.
- `AppConfig.secure` gives you full control, including mutual TLS.

## 1. Create a Local Certificate

[mkcert](https://github.com/FiloSottile/mkcert) creates certificates that your machine trusts:

```bash
brew install mkcert        # or see mkcert's install docs
mkcert -install            # once per machine
mkcert -key-file certificates/localhost-key.pem -cert-file certificates/localhost.pem localhost 127.0.0.1 ::1
```

Add `certificates/` to `.gitignore`.

## 2a. Pass It to `revali dev`

```bash
dart run revali dev --cert certificates/localhost.pem --key certificates/localhost-key.pem
```

The server now serves `https://localhost:8080/api` on the host and port from your app. You must pass both flags or neither.

<Callout type="note">

The startup line still reads `Serving at http://…`, followed by `TLS enabled via --cert/--key`. The server is serving HTTPS: only the scheme in the log line is wrong.

</Callout>

## 2b. Or Use `AppConfig.secure`

Use `AppConfig.secure` when you build the `SecurityContext` yourself, for example to choose a certificate per flavor, or to require client certificates:

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'dart:io';

import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  MainApp() // not const: SecurityContext isn't const
      : super.secure(
          host: 'localhost',
          port: 8443,
          securityContext: SecurityContext()
            ..useCertificateChain('certificates/localhost.pem')
            ..usePrivateKey('certificates/localhost-key.pem'),
        );
}
```

</CodeFile>

| Parameter | Default | Description |
| --- | --- | --- |
| `securityContext` | required | Holds the certificate chain and private key. |
| `requestClientCertificate` | `false` | Asks clients for a certificate (mutual TLS). |
| `host`, `port`, `prefix`, `workers`, `backlog` | same as `AppConfig` | |

If you use both methods, `--cert` and `--key` take precedence over the app's `securityContext`.

## Connecting from Another Device

Another device must also trust the mkcert root CA. Run `mkcert -CAROOT` to find the CA, and install it on the device. Alternatively, create the certificate for your machine's LAN IP (for example `192.168.1.50`) and connect to that address.
