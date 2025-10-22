---
sidebar_position: 4
description: Hot reload your server to see your changes in real-time
---

# Hot Reload

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

Press `r` in the terminal where Revali is running:

```console
$ dart run revali dev
[INFO] Starting the development server...
[INFO] Server running on http://localhost:8080

# Press 'r' to force regeneration
r
[INFO] Regenerating server code...
[INFO] Server reloaded successfully
```

### Using the CLI

You can also restart the entire development process:

```bash
# Stop the current server (q or Ctrl+C)
# Then restart
dart run revali dev
```
