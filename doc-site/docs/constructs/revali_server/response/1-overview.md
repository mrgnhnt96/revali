---
title: Overview
---

# Response

The `Response` is the object that represents the outgoing HTTP response. It contains all the information about the response, such as the headers, the body, and the status code. Other than the body, it is encouraged to use the Lifecycle Components to modify the response.

## Read-Only

The response is only occasionally read-only, like in the [Bind Context](../context/bind-context) and [Observer](../lifecycle-components/observer) Lifecycle Component. This is by design, as the response should be modified by the dedicated Lifecycle Components.

:::tip
Read more about Lifecycle Components [here](../lifecycle-components/overview).
:::

## Restricted Mutability

In most lifecycle components, the response mutability is restricted. The only property that is restricted in the response, is the `statusCode`, which can only be modified _after_ the endpoint has been executed (via the [Interceptor.post](../lifecycle-components/interceptors#post) method).

## Accessing the Response

### Via Context

The `Response` object can be accessed through the `response` property in the context of the Lifecycle Components.

:::tip
Read more about the Lifecycle Component's context [here](../context/overview).
:::

### Via Binding

The `Response` object can be accessed via the controller's endpoint by adding the `ReadOnlyResponse` parameter to the endpoint method.

```dart
@Get()
Future<void> helloWorld(
    MutableResponse response,
) async {
    ...
}
```

:::warning
Using the `MutableResponse` parameter in the endpoint method is not recommended. Use the `context` from Lifecycle Components to access the response.

By avoiding the `MutableResponse` parameter, you can keep your endpoint methods clean, focused, and testable.
:::