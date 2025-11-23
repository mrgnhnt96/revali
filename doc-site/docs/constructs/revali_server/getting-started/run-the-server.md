---
title: Run the Server
description: Start your development server and see your API come to life
sidebar_position: 4
---

# Run the Server

Now that you've created your first endpoint, it's time to see it in action! Revali's development server makes it incredibly easy to run and test your API.

## Starting the Development Server

From your project root, run:

```bash
dart run revali dev
```

This single command does everything you need:

- ✅ Compiles your Dart code
- ✅ Generates server files
- ✅ Starts the HTTP server
- ✅ Enables hot reload for instant updates

## Testing Your API

### Your First API Call

Open your browser and navigate to your endpoint:

```text
http://localhost:8080/api/hello
```

You should see:

```json
"Hello, World!"
```

🎉 **Congratulations!** Your API is working!

### Understanding the URL Structure

- **Base URL**: `http://localhost:8080`
- **API Prefix**: `/api` (automatically added)
- **Controller Route**: `/hello` (from your `@Controller('hello')`)
- **Method Route**: Empty (from your method name `Get()`)
- **Full URL**: `http://localhost:8080/api/hello`

## Understanding Generated Files

Revali automatically generates server files in the `.revali` directory:

```tree
.revali/
└── server/
    ├── server.dart             # Main server entry point
    ├── routes/                 # Routes definitions
    │   └── __hello_route.dart  # Hello controller
    └── ...                     # Other generated files
```

:::important
**Never modify generated files manually!** Revali manages these files automatically. Any changes you make will be overwritten.
:::

## Development Workflow

### Hot Reload Magic

One of the best features of Revali's development server is hot reload:

1. **Make changes** to your controller
2. **Save the file** (Ctrl+S / Cmd+S)
3. **See changes instantly** - no restart needed!

Try it now:

1. Change the return value in your `hello()` method
2. Save the file
3. Refresh your browser
4. See the new response immediately!

### Stopping the Server

To stop the development server:

- Press `q` (or `Ctrl+C`) in the terminal
- The server will shut down gracefully

## Troubleshooting

### Common Issues

**Server won't start?**

- Check that all dependencies are installed: `dart pub get`
- Ensure you're in the project root directory
- Look for error messages in the terminal

**Can't access the API?**

- Make sure the server is running (you should see the startup message)
- Check the URL - it should be `http://localhost:8080/api/hello`
- Try a different browser or clear your browser cache

**Changes not reflecting?**

- Ensure hot reload is working
- Try stopping and restarting the server
- Check for syntax errors in your Dart code

### Getting Help

If you run into issues:

1. **Check the terminal output** - Revali provides detailed error messages
2. **Verify your code** - Make sure your controller follows the naming conventions
3. **Restart the server** - Sometimes a fresh start helps
4. **Check the documentation** - Each component has detailed guides

## What's Next?

Your server is now running! Here are some next steps to explore:

### Immediate Next Steps

1. **Add more endpoints** - Try different HTTP [methods](/constructs/revali_server/core/methods) and routes
2. **Add parameters** - Learn how to handle [query](../core/binding#query---query-parameters) parameters and [path](/constructs/revali_server/core/methods#path-parameters) variables
3. **Return complex data** - Try returning objects and lists
4. **Access Control** - Learn how to [control access](/constructs/revali_server/access-control/allow-origins) to your endpoints

### Production Deployment

1. **Environment configuration** - Set up different [environments](/revali/app-configuration/flavors)
2. **Monitoring** - Add logging and metrics

## Pro Tips

:::tip
**Keep the terminal open** - The development server shows useful information about requests and errors
:::

:::tip
**Use a REST client** - Tools like Postman or Insomnia make testing APIs much easier
:::

:::tip
**Check the generated files** - They show you exactly how Revali interprets your code
:::

Ready to build something amazing? Your development environment is set up and ready to go!
