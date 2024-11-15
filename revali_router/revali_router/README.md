# Revali Router

Revali Router is designed to integrate with [Revali](https://pub.dev/packages/revali)'s core server construct, [revali_server](https://pub.dev/packages/revali_server). Nevertheless, it can also function independently as a package to build an HTTP router for your Dart applications.

## Documentation

The documentation for the [Revali Server construct](https://www.revali.dev/constructs/revali_server) provides a comprehensive guide on the classes used within this package. The difference being that the you'd be manually creating the server instance instead of using Revali to generate it for you.

## Example

```dart
Router(
  routes: [
    Route(
      '',
      method: 'GET',
      handler: (context) async {},
    ),
    Route(
      'user',
      catchers: [],
      routes: [
        Route(
          ':id',
          catchers: [],
          guards: [],
          handler: (context) async {
            context.response.statusCode = 200;
            context.response.body = {'id': 'hi'};
          },
          interceptors: [],
          meta: (m) {},
          method: 'GET',
          middlewares: [],
          routes: [],
        ),
        Route(
          '',
          method: 'POST',
          handler: (context) async {
            final body = context.request.body;
            print(body);

            context.response.statusCode = 200;
            context.response.body = {'id': 'hi'};
          },
        ),
      ],
    ),
  ],
)
```
