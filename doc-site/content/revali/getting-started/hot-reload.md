---
title: Hot Reload
description: Hot reload your server to see your changes in real-time
---

Hot reload is one of Revali's most powerful development features. It automatically detects changes to your code and instantly applies them to your running server, allowing you to see changes in real-time without manual restarts.

## How Hot Reload Works

When you make changes to your server-side code, Revali automatically:

1. **Detects Changes**: Monitors files in watched directories
2. **Re-analyzes Code**: Processes your controllers and routes
3. **Regenerates Server**: Updates the server implementation
4. **Reloads Server**: Applies changes without losing state
5. **Preserves Connections**: Maintains active client connections

## Watched Directories

Revali monitors these directories for changes:

- **`./routes/**`\*\* - All controller files and subdirectories
- **`./lib/components/**`\*\* - Lifecycle components (middleware, guards, etc.)

### Customizing Watched Paths

Configure paths to exclude from hot reload in `revali.yaml`:

```yaml
hot_reload:
  exclude:
    - lib/generated   # Don't reload when generated code changes
    - docs            # Ignore documentation changes
```

Paths can be relative (to `revali.yaml`) or absolute. See [Revali Configuration](/revali/revali-configuration#hot-reload-configuration) for details.

### What Triggers Hot Reload

✅ **These changes trigger hot reload:**

- Adding new controller files
- Modifying existing controllers
- Adding new endpoints
- Changing route annotations
- Updating middleware or guards
- Modifying component files

❌ **These changes don't trigger hot reload:**

- Files outside watched directories
- Configuration files (unless they affect routes)
- Static assets
- Documentation files

## Hot Reload Benefits

### ⚡ **Instant Feedback**

- See changes immediately without restarting
- Maintain development flow and momentum
- Test API changes in real-time

### 🛠️ **Development Efficiency**

- No manual server restarts
- Faster iteration cycles
- Reduced context switching

## Hot Reload Limitations

### ⚠️ **State Management**

- Database connections may need to be re-established
- WebSocket connections will be terminated

## Manual Regeneration

Sometimes you need to force a complete regeneration:

### Using the Terminal

While `revali dev` is running:

| Key | Action |
|-----|--------|
| `r` | Force regenerate + restart |
| `c` | Clear and reprint the status board |
| `q` | Quit |

```console
$ dart run revali dev
12:34:56 PM [READY]
Serving at http://localhost:8080/api
Press: r reload, c clear, q quit

# Press 'r' to force regeneration
12:35:10 PM [RELOAD]
Serving at http://localhost:8080/api
Press: r reload, c clear, q quit
```

Without a TTY, write to `.revali_cmd` in the project root (`reload`, `clear`, or `quit`).

### Using the CLI

You can also restart the entire development process:

```bash
# Stop the current server (q or Ctrl+C)
# Then restart
dart run revali dev
```
