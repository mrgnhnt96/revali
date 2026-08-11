---
title: revali routes
description: List the routes generated for your Revali application
---

The `revali routes` command lists the routes generated for your application by reading `.revali/server/routes.json`.

## Basic Usage

```bash
dart run revali routes
```

Example output:

```text
prefix: /api  (2 routes)

GET      /users        →  UserController.getUsers
POST     /users        →  UserController.createUser
```

## Options

| Flag | Description |
| --- | --- |
| `--generate`, `-g` | Regenerate the server construct before reading the manifest. |
| `--json` | Print the raw `routes.json` contents instead of the formatted list. |

## Generating the Manifest First

`routes.json` is written whenever the server construct is generated (for example by `revali dev` or `revali dev --generate-only`). If it doesn't exist yet, `revali routes` will tell you so:

```bash
dart run revali routes --generate
```

This runs generation once (without starting the dev server) and then prints the routes.

## Next Steps

- **[The Doctor Command](/revali/cli/doctor)**: Diagnose kernel, construct, and generated-output issues
- **[The Dev Command](/revali/cli/dev)**: Start the development server
