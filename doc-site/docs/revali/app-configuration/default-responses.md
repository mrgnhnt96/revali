# Default Responses

The default responses are the responses that are returned during certain events in the request flow. To customize the responses, you can override the `defaultResponses` method in your `AppConfig` class.

```dart title"routes/apps/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
class MyApp extends AppConfig {
    @override
    // highlight-start
    DefaultResponses get defaultResponses => DefaultResponses();
}
```

## Internal Server Error

The internal server error response is returned when an exception is thrown and the status code is set to 500 or higher.

```dart title"routes/apps/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
class MyApp extends AppConfig {
    @override
    DefaultResponses get defaultResponses => DefaultResponses(
        // highlight-start
        internalServerError: SimpleResponse(
            statusCode: 500,
            body: 'Uh oh! Something went wrong!',
        ),
        // highlight-end
    );
}
```

The default internal server error response is

```dart
SimpleResponse(
    statusCode: 500,
    body: 'Internal Server Error',
);
```

## Not Found

The not found response is returned when no route is found for the request.

```dart title"routes/apps/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
class MyApp extends AppConfig {
    @override
    DefaultResponses get defaultResponses => DefaultResponses(
        // highlight-start
        notFound: SimpleResponse(
            statusCode: 404,
            body: 'Page not found',
        ),
        // highlight-end
    );
}
```

The default not found response is

```dart
SimpleResponse(
    404,
    body: 'Not Found',
)
```

## Failed CORs Origin

When a request is made from an origin that is not allowed by the CORS policy, the failed CORS origin response is returned.

```dart title"routes/apps/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
class MyApp extends AppConfig {
    @override
    DefaultResponses get defaultResponses => DefaultResponses(
        // highlight-start
        failedCorsOrigin: SimpleResponse(
            statusCode: 403,
            body: 'Failed CORs due to origin',
        ),
        // highlight-end
    );
}
```

The default failed response is

```dart
SimpleResponse(
    403,
    body: 'CORS policy does not allow access from this origin.',
)
```

## Failed CORs Headers

When a request is made with headers that are not allowed by the CORS policy, the failed CORS headers response is returned.

```dart title"routes/apps/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
class MyApp extends AppConfig {
    @override
    DefaultResponses get defaultResponses => DefaultResponses(
        // highlight-start
        failedCorsHeaders: SimpleResponse(
            statusCode: 403,
            body: 'Failed CORs due to headers',
        ),
        // highlight-end
    );
}
```

The default failed response is

```dart
SimpleResponse(
    403,
    body: 'CORS policy does not allow access with these headers.',
)
```
