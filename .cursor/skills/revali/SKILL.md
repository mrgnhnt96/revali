---
name: revali
description: >-
  Build and debug Revali APIs (controllers, LifecycleComponents, params,
  codegen). Use when editing routes/, revali annotations, .revali output,
  sip run ts/ut, or dart run revali.
---

# Revali

Read [AGENTS.md](../../../AGENTS.md) at the repo root for conventions.

## Prefer MCP when available

If the `revali_mcp` server is configured, use `list_routes`, `get_route`, `doctor`, `recent_requests`, and `create_scaffold` before grepping `.revali/`.

## Do

- Put controllers under `routes/` as `*_controller.dart`
- Prefer `LifecycleComponent` over classic Middleware interfaces
- `await createServer(server)` in tests
- `--recompile` after editing construct makers

## Don't

- Hand-edit `.revali/`
- Assume raw JSON bodies without the `data` envelope
- Expect HTTP 500 for missing query/body — it is **400**
