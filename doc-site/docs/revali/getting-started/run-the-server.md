---
sidebar_position: 2
---

# Run the Server

On it's own, revali doesn't do anything except analyze your routes and prepare it for constructs to generate code. In order to see your server in action, you'll need to use a "Server Construct" to generate the server code.

:::tip
Check out the [Revali Server][revali-server] construct for more information on how to generate a server.
:::

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

[revali-server]: ../../constructs/revali_server/overview.md
