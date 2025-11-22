---
sidebar_position: 2
description: Run your server to see your API in action
---

# Run the Server

Now that you've created your first endpoint, let's start the development server and see your API in action.

## Start the Development Server

Revali provides a CLI tool to run your server. From your project root, run:

```bash
dart run revali dev
```

This command will:

1. Analyze your routes and controllers
2. Generate the necessary server code
3. Start the development server
4. Enable hot reload for instant development feedback

## Server Configuration

By default, Revali configures your server with these settings:

- **Host**: `localhost`
- **Port**: `8080`
- **API Prefix**: `/api`

## Access Your API

Once the server is running, you can access your API at:

```text
http://localhost:8080/api
```

For your hello endpoint created in the previous guide:

```text
GET http://localhost:8080/api/hello
```

## Generated Files

When Revali starts, it generates files in your project:

```tree
.
└── .revali/
    └── server/
        ├── <generated-files>
        └── server.dart
```

:::warning
**Important**: Never modify files in the `.revali` directory manually. Revali manages these files automatically and will overwrite any changes you make.
:::

## Hot Reload

One of Revali's best features is hot reload support. When you make changes to your controllers:

1. Save your file
2. Revali automatically detects the changes
3. Regenerates the necessary code
4. Restarts the server
5. Your changes are live instantly!

## Testing Your API

You can test your API using various tools:

### Using curl

```bash
curl http://localhost:8080/api/hello
```

### Using a REST Client

Tools like [Postman](https://www.postman.com/), [Insomnia](https://insomnia.rest/), or [Thunder Client](https://www.thunderclient.com/) work great for testing APIs.

## Development Tips

- **Keep the terminal open**: The development server shows logs and error messages
- **Check the console**: Revali provides helpful feedback about route generation
- **Use hot reload**: Make changes and see them instantly without restarting

## Next Steps

:::tip
Ready to add more features? Check out these guides:

- [Debug the Server](/revali/getting-started/debug-server) - Debug your server-side code

- [Hot Reload](/revali/getting-started/hot-reload) - Learn about hot reload features

- [Revali Server](/constructs/revali_server/overview) - Advanced server features

  :::

## Troubleshooting

### Port Already in Use

If port 8080 is already in use, you can change it in your app configuration:

```dart title="lib/main.dart"
import 'package:revali_core/revali_core.dart';

void main() {
  AppConfig(
    port: 3000, // Use a different port
  );
}
```

### Server Crashes or Other Issues

If you encounter other issues:

1. Check the error messages in the terminal for clues
2. Verify your code matches the examples in the documentation
3. Try running `dart pub get` to refresh dependencies
4. If the problem persists, [create an issue](https://github.com/mrgnhnt96/revali/issues/new) with:
   - A description of the problem
   - Steps to reproduce
   - Error messages/logs
   - Your environment details (Dart version, OS, etc.)
