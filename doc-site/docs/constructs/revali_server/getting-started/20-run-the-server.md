---
title: Run the Server
---

# Run the Server

## Revali CLI

Revali provides a CLI tool to run your server. To start the server, run the following command in your terminal from the root of your project:

```bash
dart run revali dev
```

## Server Started

Out of the box, Revali configures your server to serve the API at `http://localhost:8080/api`.

Now, open your browser and navigate to `http://localhost:8080/api`. You should see the response from your endpoint.

```text
Not Found

__DEBUG__:
Error: RouteNotFoundException: GET api

Stack Trace:
package:revali_router/src/router/router.dart 138:34          Router.handle
package:revali_router/src/server/handle_requests.dart 23:33  handleRequests
```

This error is expected because we haven't defined a route for the `/api` path yet. If we go the `/hello` (`http://localhost:8080/api/hello`) path, we should see the response from our endpoint.

```json
{
  "data": "Hello, World!"
}
```

## Generated Files

When revali starts up, it will generate files in your project:

```tree
.
└── .revali
    └── server
        ├── <generated-files>
        └── server.dart
```

These files are your server's definitions and routes. These files should **NOT** be modified manually, Revali will manage them for you.

## Next Steps

Now that you've seen your server in action, you can start adding more endpoints to your server.

:::tip
Check out the [revali docs](/revali/getting-started/debug-server) to learn more about debugging your server.
:::
