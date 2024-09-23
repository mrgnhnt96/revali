# Debug the Server

Revali automatically starts up a VM service for you to connect to. This allows you to debug your server-side code using your favorite IDE.

Meaning you can set breakpoints, inspect variables, and step through your code!

## Connecting to the VM Service

### VS Code

1. Open the command palette (`Ctrl+Shift+P` or `Cmd+Shift+P`).
2. Search for `Dart: Attach to Process`.
3. Copy the URL provided in the terminal.

    - The terminal will contain a line

        ```console
        The Dart VM service is listening on http://127.0.0.1:8080/ykhykCh6zyY=/
        ```

    - The URL in this case is: `http://127.0.0.1:8080/ykhykCh6zyY=/`

4. Paste the URL in the input box and press `Enter`.

:::info
If you're running a Flutter application or your server is not located in the root of your project, VS Code may try to connect to the wrong process automatically. In this case, open the root of your server directory in a new VS Code window and try again.
:::
