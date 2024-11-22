---
sidebar_position: 7
---

# Response Handler

## Overview

The Response Handler in Revali is a low-level feature that allows developers to customize how the response is sent to the client. For most use cases, the default response handler implementation should cover all scenarios. However, in certain specific circumstances, you may need to implement your own response handler to meet unique requirements.

:::caution
This feature is intended for advanced use cases. For standard application development, we strongly recommend sticking with the default handler to ensure correct behavior and optimal performance.
:::

## Default Response Handler

The default response handler implementation (`DefaultResponseHandler`) is responsible for processing different types of responses and ensuring they are properly formatted and sent to the client. This handler deals with various response scenarios, such as managing HTTP headers, determining transfer encoding, and flushing content to the client.

### Key Responsibilities of DefaultResponseHandler

1. **Headers Management**: Determines appropriate headers to send based on the response, and applies necessary modifications to ensure consistency.
2. **Encoding and Chunking**: Manages the transfer encoding of responses to ensure compatibility with the underlying HTTP library, de-chunking if necessary.
3. **Body Streaming**: Reads the response body (if present) and streams it to the client.
4. **Handling Special Cases**: Removes content-related headers for certain status codes like `204 No Content` or `304 Not Modified`. Removes access control headers for status code `404 Not Found`.

## Create a Custom Response Handler

To create a custom response handler, you need to implement the `ResponseHandler` interface. This interface defines a single method, `handle`.

```dart
import 'package:revali_router/revali_router.dart';

class CustomResponseHandler implements ResponseHandler {
  const CustomResponseHandler();

  @override
  Future<void> handle(
    ReadOnlyResponse response,
    RequestContext context,
    HttpResponse httpResponse,
  ) async {
    // Custom response handling logic
  }
}
```

## Register the Custom Response Handler

To register your custom response handler, annotation your class on the app, controller, or endpoint level.

```dart
import 'package:revali_router/revali_router.dart';

@App()
// highlight-next-line
@CustomResponseHandler()
class MyApp ...
```

:::warning
WebSockets do not support custom response handlers. They will be ignored if registered.
:::

### Scoping

The response handler can be registered at different levels of the application, however, the handler scope closest to the endpoint will take precedence.

### Example of Response Handler Scoping

The scope of a response handler determines where it will be applied within the application. Here are the different levels at which you can register a response handler:

- **App Level**: If registered at the app level, the response handler will be used for all endpoints in the application.
- **Controller Level**: If registered at the controller level, the response handler will be used for all endpoints within that specific controller.
- **Endpoint Level**: If registered at the endpoint level, the response handler will be used only for that specific endpoint.

The response handler registered closest to the endpoint will take precedence over those registered at higher levels.
