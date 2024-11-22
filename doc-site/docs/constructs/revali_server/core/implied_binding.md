---
sidebar_position: 3
---

# Implied Binding

There are certain classes that do not need [binding annotations][binding].

:::warning
It is highly discouraged to used these, prefer to use [binding] with a [pipe][pipes] or [Lifecycle Components][lifecycle-components]. Using these can make testing harder and make your code harder to understand.
:::

| Types | |
| --- | --- |
| DI | Dependency Injection, where all your dependencies are configured |
| MutableHeaders | The headers that will sent with the response |
| MutableBody | The body that will be sent with the response |
| MutableResponse | The response to be sent |
| ReadOnlyBody | The body received with the request |
| ReadOnlyHeaders | The headers that were received with the request |
| ReadOnlyRequest | The received request |

[binding]: ./binding.md
[pipes]: ./pipes.md
[lifecycle-components]: ../lifecycle-components/overview.md
