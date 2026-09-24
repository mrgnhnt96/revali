---
title: Run the Server
description: Start the dev server, hot reload, debug, and know what gets generated.
---

Run this from the package root, the directory with `pubspec.yaml` and
`routes/`:

```bash
dart run revali dev
```

`dev` analyzes `routes/`, generates the server into `.revali/`, starts it, and
prints a status board:

```console
12:34:56 PM [READY]
Serving at http://localhost:8080/api
The Dart VM service is listening on http://127.0.0.1:53211/abc123=/
Press: r reload, c clear, q quit

/hello
GET -> /hello
GET -> /hello/:name
```

```bash
curl http://localhost:8080/api/hello
# {"data":"Hello, World!"}
```

## While it runs

| Key | Action |
| --- | --- |
| `r` | Regenerate and restart |
| `c` | Clear the screen and reprint the status board |
| `q` | Quit (`Ctrl+C` also works) |

Without a terminal (CI, a script, an AI agent), write `reload`, `clear` or
`quit` to a file named `.revali_cmd` in the package root instead.

## Hot reload

Saving a file anywhere in the package regenerates `.revali/` and **restarts the
server process**. That keeps new and deleted controllers correct, but it means
in-memory state, open database connections and WebSocket clients do not
survive a reload. Paths you don't want to trigger a reload can be excluded in
[`revali.yaml`](/revali/revali-configuration).

## Debugging

The status board prints the Dart VM service URL. Attach your IDE to it:

- **VS Code:** run **Dart: Attach to Process** from the command palette and
  paste the URL.
- **IntelliJ / Android Studio:** create a **Dart Remote Debug** run
  configuration with the URL.

Breakpoints in controllers and components then work as usual. The port is
random unless you pass `--dart-vm-service-port`. After a hot reload the process
is new, so re-attach.

## Generated files

```tree
.revali/
└── server/
    ├── server.dart     # entrypoint; also exports createServer() for tests
    └── routes/         # one file per controller
```

`.revali/` is regenerated on every run. Never edit it; add it to `.gitignore`.

## What's next

- Every `dev` flag (flavors, `--release`, `--dart-define`, HTTPS):
  [`revali dev`](/revali/cli/dev)
- Test endpoints in-process without a port: [Testing](/revali/testing)
- Compile for production: [`revali build`](/revali/cli/build)
- Something wrong? Run [`dart run revali doctor`](/revali/cli/doctor).
