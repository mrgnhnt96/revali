# Request

The `Request` is the object that represents the incoming HTTP request. It contains all the information about the request, such as the headers, the body, the URL, and the method. While the [response](./../response/overview) can be heavily modified, the request is read-only, with the exception of the headers.

## Read-Only

The request is read-only, meaning that you cannot modify the request body, URL, method, or any other property of the request. This is because the request is already sent by the client, and the server should respond to the request as it is.

:::important
Only the headers can be modified in the request
:::
