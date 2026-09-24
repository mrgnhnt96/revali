---
title: revali routes
description: List the generated routes, and check them against a pinned manifest for contract drift
---

`revali routes` prints the routes in your generated server, read from `.revali/server/routes.json`. With `--check`, it compares them against a saved copy and fails when a caller could break. Use that as a CI gate.

```bash
dart run revali routes --generate
```

```text
prefix: /api  (2 routes)

GET     /api/users  →  UserController.getUsers
POST    /api/users  →  UserController.createUser
```

## Options

| Flag | Description |
| --- | --- |
| `--generate`, `-g` | Regenerates the server before reading the manifest. Required when `.revali/` doesn't exist yet, as on a clean CI checkout. |
| `--json` | Prints the raw `routes.json`. |
| `--check <path>` | Compares the current manifest against a saved copy (a pin) and exits `1` on a breaking change. |

`routes.json` is written every time the server is generated, by `revali dev`, `revali dev --generate-only`, or `revali routes --generate`.

## Checking for Contract Drift

A pin is a saved copy of `routes.json` that records what a caller depends on. Commit it, then check your code against it in CI:

```bash
# Create or update the pin (do this when you make a breaking change on purpose)
dart run revali routes --generate --json > contracts/pinned-routes.json

# In CI, on every pull request
dart run revali routes --generate --check contracts/pinned-routes.json
```

```text
  compatible  GET /api/users: new optional parameter 'sort'
  compatible  GET /api/users/:id: parameter 'expand' removed; callers sending it are now ignored
  BREAKING    POST /api/users: new required parameter 'tenant'
  BREAKING    GET /api/orders/:id: return value is now nullable

2 breaking change(s)
```

### What Is Breaking

A change is breaking when a caller that works today would fail after it.

| Change | Severity |
| --- | --- |
| Route removed | **Breaking** |
| Route added | Compatible |
| New required parameter | **Breaking** |
| New optional parameter | Compatible |
| Parameter became required | **Breaking** |
| Parameter became optional | Compatible |
| Parameter type changed | **Breaking** |
| Parameter moved (for example `@Query` → `@Body`) | **Breaking** |
| Parameter removed | Compatible (reported, because the value is now ignored) |
| Return type changed | **Breaking** |
| Return value became nullable | **Breaking** |
| Return value became non-nullable | Compatible |
| SSE or WebSocket turned on or off | **Breaking** |

The comparison follows these rules:

- **Routes are keyed by `METHOD path`.** Changing `@Get` to `@Post` on the same path shows up as a removal plus an addition, and the removal is breaking.
- **Parameters are matched by their wire name** (`@Query('id')` → `id`), not by their Dart name. A parameter with no binding annotation is matched by its Dart name.
- **Return types are compared after `await`**, so `Future<String>` and `String` count as the same type.
- **Handler and controller names are ignored**, because callers can't see them.
- **Only the route surface is compared.** The check covers methods, paths, parameters and the top-level return type name. It doesn't look at the fields inside a returned type.
- **Pins from before manifest version 2** have no return types. The check prints a compatible note saying return types weren't compared. Regenerate the pin to include them.

### Exit Codes

| Situation | Exit code |
| --- | --- |
| No changes, or only compatible changes | `0` |
| At least one breaking change | `1` |
| The pin is missing, or either manifest can't be read | `1` |
