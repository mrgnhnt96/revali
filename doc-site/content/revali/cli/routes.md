---
title: revali routes
description: List the routes generated for your Revali application, and check them against a pinned manifest for contract drift
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
| `--check <path>` | Compare the current manifest against a pinned `routes.json` and exit non-zero on breaking changes. See [Checking for Contract Drift](#checking-for-contract-drift). |

## Generating the Manifest First

`routes.json` is written whenever the server construct is generated (for example by `revali dev` or `revali dev --generate-only`). If it doesn't exist yet, `revali routes` will tell you so:

```bash
dart run revali routes --generate
```

This runs generation once (without starting the dev server) and then prints the routes.

## Checking for Contract Drift

When another service or app calls your Revali server, it depends on a shape it can't see: the paths that exist, the parameters they read, where those parameters come from, and what comes back. Nothing in Dart's type system spans that gap. You can rename a route, tighten a parameter, or make a return value nullable, and your own build stays green — the failure surfaces later, at runtime, in somebody else's deployment.

`--check` closes that gap by turning the manifest into something a consumer can pin:

```bash
dart run revali routes --check contracts/pinned-routes.json
```

It compares the current `.revali/server/routes.json` against the pinned copy and exits `1` if a caller that built against the pin could now break. That exit code is the whole point — it makes the check usable as a CI gate, so the break is caught on the pull request that causes it rather than in production.

### What This Is Not

`routes.json` describes a route *surface*: methods, paths, parameter names, locations, whether each is required, and the top-level name of what each handler returns. It carries no field lists, no nested types, and no serialization strategy. It cannot generate a typed client and doesn't try to. What it can tell you is that the producer moved underneath a consumer — which is the part that actually breaks deployments.

So a check that passes means "no route you already call has changed shape at the surface." It does not mean "the JSON body of `User` is unchanged." Treat it as a drift alarm, not a schema.

### Severity Is Judged from the Caller's Side

Every difference is classified as **breaking** or **compatible**, and the question asked is always the same: *would a consumer that was already calling this route still work?* That framing is what makes the gate quiet enough to leave switched on — a change is only breaking if it invalidates calls that already exist.

| Change | Severity | Why |
| --- | --- | --- |
| Route removed | **Breaking** | Calls to it now 404. |
| Route added | Compatible | Nothing existing is affected. |
| New **required** parameter | **Breaking** | Every call the consumer already makes is now missing it. |
| New **optional** parameter | Compatible | Existing calls stay valid. |
| Existing parameter became required | **Breaking** | Callers omitting it are now rejected. |
| Existing parameter relaxed to optional | Compatible | Callers already send it. |
| Parameter type changed | **Breaking** | The value the caller sends may no longer parse. |
| Parameter moved location (e.g. `@query` → `@body`) | **Breaking** | The caller is sending it in the wrong place. |
| Parameter **removed** | Compatible | See below. |
| Return type changed | **Breaking** | The caller is decoding the wrong shape. |
| Return value became nullable | **Breaking** | The caller may be reading it without a null check. |
| Return value stopped being nullable | Compatible | A caller that handles null still handles non-null. |
| Transport changed (SSE or WebSocket toggled) | **Breaking** | A plain request can't consume a stream, or the reverse. |

The one that surprises people is **a removed parameter, which is compatible, not breaking**. A server that stops reading a parameter still accepts a caller that sends it — the request succeeds, nothing 400s. It is still reported, because the caller's value is now silently ignored and that's usually worth someone's attention, but it will not fail the gate. If a caller was passing `?page=3` and the server stopped honoring it, you want to see the line; you do not want a red build blocking an unrelated release.

Note also that routes are keyed by `METHOD path`. Changing a handler from `@Get` to `@Post` on the same path is therefore reported as a removal *and* an addition, not as a modification — and the removal is what fails the gate, correctly, because the consumer's `GET` is now gone.

Handler and controller names are deliberately not compared. Those are the producer's business; renaming a class is not something a caller can observe.

### Parameters Match on the Wire Name

Comparison is keyed by the name that goes over the wire, not the Dart parameter name. Given:

```dart
@Get('/users')
Future<User> getUser(@Query('id') String userId) async { ... }
```

the manifest records that parameter as `id`. Renaming `userId` to `id`, or to anything else, while leaving `@Query('id')` alone changes nothing a caller can see — and the check reports nothing. Change the annotation to `@Query('userId')` and you have renamed the contract: the check sees `id` removed and `userId` added, and if the new one is required, that's breaking.

Parameters with no binding annotation fall back to their Dart name.

### Return Types Are Reported Unwrapped

The manifest records the *awaited*, non-nullable type name plus a separate nullability flag. `Future<String>` and `String` are therefore the same contract, because what a caller receives is the awaited value either way. Without this, making a handler `async` would flag a breaking change on a route whose observable behavior didn't move — and nullability would be read off `Future` rather than off what is actually returned.

### Manifest Versions

Return types arrived in **manifest version 2**. A pin captured before that has nothing to compare against, so rather than reading "absent" as "unchanged" — which would report a clean check for a comparison it never made — the check says so explicitly:

```text
  compatible  manifest: return types not compared: one side predates manifest version 2. Re-pin against a current manifest to include them.
```

The note is compatible severity, so it will not fail your build, but it is telling you the gate is running with one eye closed. Re-pin against a freshly generated manifest to get return-type coverage back.

### Reading the Output

Compatible changes print first, then breaking ones, each prefixed with its severity and the route it belongs to:

```text
  compatible  GET /api/users: new optional parameter 'sort'
  compatible  GET /api/users/:id: parameter 'expand' removed; callers sending it are now ignored
  BREAKING    POST /api/users: new required parameter 'tenant'
  BREAKING    GET /api/orders/:id: return value is now nullable

1 breaking change(s)
```

Exit codes:

| Situation | Exit code |
| --- | --- |
| No differences at all | `0` |
| Only compatible differences | `0` |
| One or more breaking differences | `1` |
| Pinned file missing | `1` |
| Either manifest unreadable or malformed | `1` |

A missing or corrupt pin fails the same way a breaking change does, on purpose: a gate that cannot read its baseline has not verified anything, and passing in that state is worse than not running.

### Using It in CI

Commit the pin next to the consumer that depends on it, and check the producer against it on every pull request:

```bash
dart run revali routes --generate --check contracts/pinned-routes.json
```

`--generate` regenerates the construct first, so the check runs against the code in the branch rather than whatever `.revali/` happened to be left in the workspace. On a clean CI checkout, where `.revali/server/routes.json` does not exist yet, it is required — without it the command has no manifest to read and fails.

When you make a breaking change on purpose, update the pin in the same pull request:

```bash
dart run revali routes --generate --json > contracts/pinned-routes.json
```

That is the moment the change becomes visible: the diff on the pinned file is the reviewable record of what consumers now have to adapt to, and it lands next to the code that caused it instead of in an incident report.

## Next Steps

- **[The Doctor Command](/revali/cli/doctor)**: Diagnose kernel, construct, and generated-output issues
- **[The Dev Command](/revali/cli/dev)**: Start the development server
