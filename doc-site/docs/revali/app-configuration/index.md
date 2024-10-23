# App Configuration

Revali's configuration is setup via classes named `App`s. This is the entry point for your Revali application, this is where you'll setup your app's hostname & port, configure your dependencies, and change the global prefix.

There is a default configuration that works out-of-the-box, but you can customize it to fit your needs. You can also create multiple configurations, called [flavors], to handle different environments.

## Default Configuration

The default configuration uses the following values:

```dart
AppConfig(
    hostname: 'localhost',
    port: 8080,
    prefix: '/api',
)
```

[flavors]: ./20-flavors.md
