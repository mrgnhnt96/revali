# Run the Server

## Revali CLI

Revali provides a CLI tool to run your server. To start the server, run the following command in your terminal from the root of your project:

```bash
dart run revali dev
```

## Server Started

Out of the box, Revali configures your server to

- Listen on port `8080`
- Serve the API at `/api`

To access the server, open your browser and navigate to `http://localhost:8080/api`.

If you have been following our example this far, you should see a response similar to the following:

```txt
Not Found

__DEBUG__:
Error: RouteNotFoundException: GET api

Stack Trace:
package:revali_router/src/router/router.dart 138:34          Router.handle
package:revali_router/src/server/handle_requests.dart 23:33  handleRequests
```

This error is expected because we have not defined any routes for `/` yet.

if you go to `http://localhost:8080/api/hello`, you should see the response:

```json
{
  "data": "Hello, World!"
}
```

## Generated Files

When revali starts up, it will generate a few files in your project directory:

```tree
.
└── .revali
    └── server
        ├── definitions
        │   ├── __public.dart
        │   ├── __reflects.dart
        │   └── __routes.dart
        ├── routes
        │   └── __hello.dart
        └── server.dart
```

These files are your server's definitions and routes. These files should **NOT** be modified manually, Revali will manage them for you.

## Hot Reload

As you make changes to your server-side code, Revali will automatically reload the server for you. This allows you to see your changes in real-time without having to restart the server manually. You can add new routes, modify existing routes, or even remove routes, and Revali will handle the rest.

## Debugging the Server

Revali automatically starts up a VM service for you to connect to. This allows you to debug your server-side code using your favorite IDE.

Meaning you can set breakpoints, inspect variables, and step through your code!

### Connecting to the VM Service

#### VS Code

1. Open the command palette (`Ctrl+Shift+P` or `Cmd+Shift+P`).
2. Search for `Dart: Attach to Process`.
3. Copy the URL provided in the terminal.
    - The terminal will contain a line

        ```console
        The Dart VM service is listening on http://127.0.0.1:8080/ykhykCh6zyY=/
        ```

    - The URL in this case is: `http://127.0.0.1:8080/ykhykCh6zyY=/`
4. Paste the URL in the input box and press `Enter`.

Note: If you're running a flutter application or your server is not located in the root of your project, VS Code may try to connect to the wrong process automatically. In this case, open a the root of your server directory in a new VS Code window and try again.

## Restart the Server

Hot Reload is great, but sometimes there's the itch to _make sure_ everything is up to date. To restart the server, press `r`. This will re-analyze your code and regenerate your server.

## Stop the Server

The server can be stopped by pressing `Ctrl+C`, but this could leave a dangling process. To stop the server gracefully, press `q`. This will stop the server, close the VM service, and clean up any resources.
