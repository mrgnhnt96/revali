---
description: Certain classes do not need binding annotations
sidebar_position: 3
---

# Implied Binding

There are certain classes that do not need [binding annotations][binding].

## Context Providers

| Types | Description |
| --- | --- |
| ReadOnlyMeta | Read meta data of the request, app, controller, endpoints |
| WriteOnlyMeta | Write meta data of the request, app, controller, endpoints |
| MetaHandler | Read and write meta data of the request, app, controller, endpoints |
| ReadOnlyMetaDetailed | Same as `ReadOnlyMeta`, with more methods to get more information about endpoints |
| DataHandler | Read and write data shared between components during a request |
| ReadOnlyData | Read data shared between components during a request |
| WriteOnlyData | Write data shared between components during a request |
| CleanUp | Clean up resources after request handling |

:::caution
Not all endpoints and lifecycle components have access to each of these types. Check the documentation of the endpoint or lifecycle component to see which types are available.
:::

## Request/Response

 ⚠️ It is discouraged to used the following types, in most cases, you can access these values via [bindings][binding], [pipes][pipes] and [Lifecycle Components][lifecycle-components]. Using these can make testing harder and make your code harder to understand.

| Types | Description |
| --- | --- |
| ⚠️ DI | Dependency Injection, where all your dependencies are configured |
| MutableHeaders | The headers that will sent with the response |
| MutableCookies | The cookies that will be sent with the response |
| ReadOnlyCookies | The cookies that were received with the request |
| MutableSetCookies | The cookies that will be sent in the `Set-Cookie` header |
| ReadOnlySetCookies | The cookies that will be sent in the `Set-Cookie` header |
| ⚠️ MutableBody | The body that will be sent with the response |
| ⚠️ MutableResponse | The response to be sent |
| ⚠️ RestrictedMutableResponse | Modify only body and headers |
| ⚠️ ReadOnlyHeaders | The headers that were received with the request |
| ⚠️ ReadOnlyRequest | The request that was received |
| ⚠️ ReadOnlyBody | The body received |
| ⚠️ MutableRequest | Modify only headers |

[binding]: ./binding.md
[pipes]: ./pipes.md
[lifecycle-components]: ../lifecycle-components/overview.md
