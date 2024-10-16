---
title: Status Code
---

# Response Status Code

The status code is a number that represents the status of the HTTP response. It is used to indicate whether a specific HTTP request has been successfully completed or not.

## Status Codes

The status codes are divided into five categories:

- **1xx** - Informational
- **2xx** - Success
- **3xx** - Redirection
- **4xx** - Client Error
- **5xx** - Server Error

### Common Status Codes

Here are some of the most common status codes:

- **200** - OK
- **201** - Created
- **204** - No Content
- **400** - Bad Request
- **401** - Unauthorized
- **403** - Forbidden
- **404** - Not Found
- **405** - Method Not Allowed
- **500** - Internal Server Error
- **501** - Not Implemented
- **503** - Service Unavailable
- **504** - Gateway Timeout

## Default Status Codes

Revali Server will set the status code whenever the status code is not set. Here are the default status codes:

- **200** - Endpoint executed successfully
- **400** - Middleware halted the request
- **403** - Guard halted the request
- **404** - Endpoint not found
- **405** - Method not allowed
- **500** - An exception was thrown

## Setting the Status Code

The status code can be set using the `Response.statusCode` property. This property is mutable, but it is restricted in most lifecycle components. The status code can only be modified _after_ the endpoint has been executed (via the [Interceptor.post](../lifecycle-components/interceptors#post) method).

### Via Context

The `Response` object can be accessed through the `response` property in the context of the Lifecycle Components.

```dart
context.response.statusCode = 200;
```

### Via Annotation

If you know the status code at compile time, you can set the status code using the `@StatusCode` annotation.

```dart
@Get()
@StatusCode(201)
Future<void> saveData() async {
    ...
}
```

### Via Binding

You can access the `statusCode` from the `Response` object which can be accessed via the controller's endpoint by adding the `MutableResponse` parameter to the endpoint method.

```dart
@Get()
Future<void> helloWorld(
    MutableResponse response,
) async {
    response.statusCode = 200;
}
```

:::warning
Using the `MutableResponse` parameter in the endpoint method is not recommended. Use the `context` from Lifecycle Components to access the response.

By avoiding the `MutableResponse` parameter, you can keep your endpoint methods clean, focused, and testable.
:::
