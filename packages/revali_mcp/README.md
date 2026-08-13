# revali_mcp

Stdio [MCP](https://modelcontextprotocol.io/) server for Revali apps. Run from the **application package root** (where `.revali/` is generated) — every tool resolves paths relative to the working directory.

Add it to the app you want to inspect:

```yaml
dev_dependencies:
  revali_mcp:
```

```bash
dart run revali_mcp
```

Or install it once for every project:

```bash
dart pub global activate revali_mcp
```

## Tools

| Tool | Description |
|------|-------------|
| `list_routes` | Read `.revali/server/routes.json` (optional `generate`) |
| `get_route` | Filter by method / path / handler |
| `doctor` | `dart run revali doctor --json` |
| `recent_requests` | Tail `.revali/inspect/requests.jsonl` (`revali dev --inspect`) |
| `create_scaffold` | `dart run revali create …` |

## Cursor

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

`cwd` must be the application package root. If you installed with `dart pub global activate`, use `"command": "revali_mcp"` with no `args` instead.
