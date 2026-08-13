# Revali — agent & contributor guide

## Quick loops

| Goal | Command |
|------|---------|
| One package | `cd <package> && dart test` |
| Everything, the way CI does | `./scripts/run_all_tests.sh` |
| Regenerate the e2e suite first | `sip run ts --gen-only` |
| Internals change needing kernel rebuild | `dart run revali dev --generate-only --recompile` |

> **Do not verify with `sip test`.** It under-reports: in
> `test_suite/constructs/revali_server/access_control`, `dart test` exits 1
> with 3 failures while `sip test` exits 0 reporting "40 passed, 0 failed",
> and from the repo root it runs nothing at all and still exits 0. Use
> `dart test` or the script above, both of which can actually go red.

## Releasing

`LATEST_CHANGELOG.md` drives the release: a package publishes only when its
entry there differs from its `pubspec.yaml` version, so **equal versions mean
skipped**, and a dependent's constraint is only rewritten if that dependent is
itself in the release. Pending work and the current per-package state are in
[RELEASING.md](./RELEASING.md).

## Project layout

- Controllers must live under `routes/` and end with `_controller.dart` or `.controller.dart`.
- Apps: `routes/apps/*_app.dart` with `@App()` extending `AppConfig`.
- Lifecycle components: prefer `lib/components/` (hot-reload watched).
- Generated output: `.revali/` (do not hand-edit).

## HTTP conventions agents forget

- Default URL prefix is **`/api`**.
- Successful JSON responses are wrapped as **`{"data": ...}`** unless the handler takes over the body.
- Missing / invalid bindings throw `MissingArgumentException` → framework responds with **HTTP 400**.
- JSON has no `Set`; prefer `List` on the wire. `Set` params are matched as `Iterable`.

## Lifecycle (preferred)

Use **`LifecycleComponent`**: method return type selects the role (`MiddlewareResult`, `GuardResult`, `InterceptorPreResult`, `ExceptionCatcherResult<T>`, …). Annotate with `@MyComponent()` or `@LifecycleComponents([MyComponent])`.

Classic `implements Middleware` / `Guard` / `ExceptionCatcher` is advanced — avoid mixing styles in one feature.

Built-in kits: `@RequestId()`, `@AllowOrigins(...)`.

## CLI

```bash
dart run revali routes [--generate] [--json]
dart run revali doctor [--json]
dart run revali create controller|app|lifecycle-component|pipe|observer
dart run revali dev [--inspect] [--skip-if-fresh] [--recompile]
```

`dev` hotkeys: `r` reload, `c` clear status board, `q` quit. Headless: write `reload`/`clear`/`quit` to `.revali_cmd`.

`create` scaffolds app/controller/lifecycle-component/pipe/observer files in-process. Prefer MCP tools when configured (`list_routes`, `doctor`, `recent_requests`, `create_scaffold`).

## Testing

```dart
setUp(() async {
  server = TestServer();
  await createServer(server); // always await — buffers until listen
});
```

Import generated `createServer` from `../.revali/server/server.dart` after generate.

## Regenerate rules

| Change | Action |
|--------|--------|
| Controller / routes only | `dart run revali dev --generate-only` (or hot reload in `dev`) |
| Construct makers / `revali_*` packages | `--recompile` (kernel embeds makers) |
| Warm suite, outputs fresh | `sip run ts --skip-gen` |

## MCP

Package: [`packages/revali_mcp`](packages/revali_mcp). Example Cursor config (run from the **app** package root that contains `.revali/`):

```json
{
  "mcpServers": {
    "revali": {
      "command": "dart",
      "args": ["run", "revali_mcp"],
      "cwd": "/absolute/path/to/your/app"
    }
  }
}
```

Tools: `list_routes`, `get_route`, `doctor`, `recent_requests`, `create_scaffold`.
