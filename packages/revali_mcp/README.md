# revali_mcp

Stdio [MCP](https://modelcontextprotocol.io/) server for Revali apps. Run from the **application package root** (where `.revali/` is generated).

```bash
dart run revali_mcp
```

## Tools

| Tool | Description |
|------|-------------|
| `list_routes` | Read `.revali/server/routes.json` (optional `generate`) |
| `get_route` | Filter by method / path / handler |
| `doctor` | `dart run revali doctor --json` |
| `recent_requests` | Tail `.revali/inspect/requests.jsonl` (`revali dev --inspect`) |
| `create_scaffold` | `dart run revali_server create …` |

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

Add a path dependency on this package from the app, or run via `dart run` with a path to this package’s bin.
