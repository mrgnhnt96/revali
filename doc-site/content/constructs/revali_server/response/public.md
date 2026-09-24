---
title: Public Files
description: Serve static files from the project's public directory
---

Files in the `public/` directory at the project root are served as static files, at the server root, without the app prefix. Use it for `favicon.ico`, `robots.txt`, images and other assets that need no endpoint.

## Example

```tree
my_app/
├── public/
│   ├── favicon.ico
│   ├── robots.txt
│   └── images/
│       └── logo.png
├── routes/
└── pubspec.yaml
```

```bash
curl http://localhost:8080/favicon.ico
curl http://localhost:8080/images/logo.png
```

## Behavior

| Detail | Value |
| ------ | ----- |
| URL | `/<path inside public/>`. The app prefix (`/api`) is **not** added. |
| Method | `GET` (and automatic `HEAD`/`OPTIONS`). |
| CORS | All origins allowed. |
| Headers | `Content-Type` from the file extension, plus `Content-Length`, `Last-Modified`, `Accept-Ranges` and `Content-Disposition`. |
| Discovery | Files are listed when the server is generated. After adding or removing a file, regenerate: press `r` in `dart run revali dev`, or run `dart run revali dev --generate-only`. |

<Callout type="danger">

Everything in `public/` is readable by anyone who knows the URL. Never put secrets or private data there.

</Callout>
