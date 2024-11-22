---
description: A preflight request that return the response headers
---

# Head Requests

## Explanation

### What Are HEAD Requests?

A HEAD request is an HTTP method that is similar to a GET request but only retrieves the headers of the response, without the actual body content. This means that the server responds with metadata about the requested resource, such as content type, length, and other headers, but does not include the resource itself.

### Why Are HEAD Requests Important?

HEAD requests are important for checking information about a resource without downloading its entire content, making them ideal for lightweight operations. They are often used to verify the existence of a resource, check its size, or see if it has been modified, all without incurring the overhead of retrieving the actual data. This helps save bandwidth and improve the efficiency of certain operations, particularly in applications where the response body is large.

For example, HEAD requests are commonly used in caching mechanisms to determine whether a resource has changed since the last request, enabling more efficient data handling.

### How Are HEAD Requests Used?

When the server responds to a HEAD request, it will provide headers like `Content-Length`, `Content-Type`, and `Last-Modified`, which can be used to gather information about the resource without retrieving its full content. This is useful for tasks like monitoring server status, validating links, or managing caches efficiently.

Using HEAD requests can help improve the performance of your application by reducing data transfer, especially in situations where only metadata is needed.

## Usage

Revali will automatically handle HEAD requests for you. When a HEAD request is received, Revali will process the request as a GET request, but will not run the endpoint's handler function. Instead, it will return only the headers of the response, without the body content.

### Manually Handling HEAD Requests

If you need to manually handle HEAD requests in your application, you can use the `@Head` annotation to define a handler function for HEAD requests.

:::important
If you define a handler function for HEAD requests, there should also be a corresponding handler function for GET requests.
:::

:::note
Don't try returning a body in a HEAD request handler. Revali will automatically strip the body content from the response.
:::

## Lifecycle

When a HEAD request is received by Revali, it will follow the same order as [an HTTP request lifecycle][lifecycle-order], the only difference is that the endpoint's handler function will not be executed (unless you have defined a handler function for HEAD requests).

[lifecycle-order]: ../lifecycle-components/overview.md#lifecycle-order
