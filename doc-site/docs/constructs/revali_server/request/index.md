# Request

The `Request` is the object that represents the incoming HTTP request. It contains all the information about the request, such as the headers, the body, the URL, and the method. While the [response] can be heavily modified, the request is read-only, with the exception of the headers.

## Read-Only

The request is read-only, meaning that you cannot modify the request body, URL, method, or any other property of the request. This is because the request is already sent by the client, and the server should respond to the request as it is.

:::important
Only the headers can be modified in the request
:::

## Accessing the Request

### Via Context

The `Request` object can be accessed through the `request` property in the context of the Lifecycle Components.

```dart
final request = context.request;
```

:::tip
Read more about the [Lifecycle Component's context][lifecycle-context].
:::

### Via Binding

The `Request` object can be accessed via the controller's endpoint by adding the `ReadOnlyRequest` parameter to the endpoint method.

```dart
@Get()
Future<void> helloWorld(
    ReadOnlyRequest request,
) async {
    ...
}
```

:::warning
Using the `ReadOnlyRequest` parameter in the endpoint method is not recommended. Use the `context` from Lifecycle Components to access the request.

By avoiding the `ReadOnlyRequest` parameter, you can keep your endpoint methods clean, focused, and testable.
:::

[response]: ./../response/index.md
[lifecycle-context]: ../context/index.md
