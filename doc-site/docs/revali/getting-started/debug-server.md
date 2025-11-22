---
sidebar_position: 3
description: Debug your server-side code using your IDE
---

# Debug the Server

Revali provides built-in debugging support that allows you to debug your server-side code using your favorite IDE. You can set breakpoints, inspect variables, step through code, and analyze the execution flow in real-time.

## How Debugging Works

When you start the Revali development server, it automatically launches a Dart VM service that your IDE can connect to. This enables full debugging capabilities for your server-side code.

## Connecting to the VM Service

### VS Code (Recommended)

1. **Open Command Palette**: Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (macOS)
2. **Search for Debug Command**: Type `Dart: Attach to Process`
3. **Get the VM Service URL**: Look for this line in your terminal:

   ```console
   The Dart VM service is listening on http://127.0.0.1:8080/ykhykCh6zyY=/
   ```

4. **Connect**: Copy the URL (e.g., `http://127.0.0.1:8080/ykhykCh6zyY=/`) and paste it into the input box
5. **Start Debugging**: Press `Enter` to connect

:::info
**Multiple Projects**: If you're running a Flutter application or your server isn't in the project root, VS Code might connect to the wrong process. Open the server directory in a new VS Code window and try again.
:::

### IntelliJ IDEA / Android Studio

1. **Open Run Configuration**: Go to `Run` → `Edit Configurations`
2. **Add New Configuration**: Click `+` and select `Dart Remote Debug`
3. **Configure Connection**:
   - Set the VM service URL from your terminal
   - Choose your project directory
4. **Start Debugging**: Run the configuration

## Debugging Features

Once connected, you can:

- **Set Breakpoints**: Click in the gutter next to line numbers
- **Step Through Code**: Use F10 (step over), F11 (step into), Shift+F11 (step out)
- **Inspect Variables**: Hover over variables or use the Variables panel
- **Evaluate Expressions**: Use the Debug Console to run code snippets
- **Call Stack**: See the execution path that led to the current point

## Troubleshooting

### Connection Issues

- **Port Conflicts**: Ensure port 8080 isn't used by other services
- **Firewall**: Check if your firewall is blocking the debug port
- **VM Service URL**: Verify the URL format matches exactly

### Debugging Not Working

- **IDE Extensions**: Ensure Dart/Flutter extensions are installed and updated
- **Project Structure**: Make sure you're debugging the correct project
- **Server Running**: Verify the Revali server is actually running

:::tip
**Hot Reload + Debugging**: You can use hot reload while debugging. Changes will be reflected immediately, and you can continue debugging with the updated code.
:::

## Next Steps

- **[Hot Reload](/revali/getting-started/hot-reload)**: Learn about automatic code reloading
- **[Error Handling](/constructs/revali_server/lifecycle-components/advanced/exception-catchers)**: Learn about exception handling
