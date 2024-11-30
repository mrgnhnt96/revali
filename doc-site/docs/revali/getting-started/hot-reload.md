---
description: Hot reload your server to see your changes in real-time
---

# Hot Reload

As you make changes to your server-side code, Revali will automatically reload the server for you. This allows you to see your changes in real-time without having to restart the server manually. You can add new routes, modify existing routes, or even remove routes, and Revali will handle the rest.

## Server Regeneration

All files within the `routes` directory will trigger Revali to re-analyze and generate the server code. This includes the `routes` directory and all subdirectories within it. If you add a new file or modify an existing file, Revali will regenerate the server code.

Revali tries to be as efficient as possible when regenerating the server code. It will only regenerate when necessary, meaning that if you make a change to a file that doesn't affect the server code, Revali will not regenerate the server code. Revali determines this by the file's location.

All files and subdirectories within the following directories will trigger a regeneration:

- ./routes/\*\*
- ./lib/components/\*\*

All other files and directories will not trigger a regeneration.

:::tip
Whether Revali regenerates the server code or not, it will always hot reload the server.
:::

### Manual Regeneration

If you need to manually regenerate the server code, you can press `r` in the terminal where the server is running. This will force Revali to re-analyze and generate the server code.
