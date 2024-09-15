# API Reference

## Annotations

### Detailed Explanation of All Annotations

Revali provides several annotations to facilitate various aspects of API development. Here’s a comprehensive list:

-   **`@Controller`**: Used to define a controller class that groups related request handlers.

    ```dart
    @Controller('/example')
    class ExampleController {
      // Controller methods
    }
    ```

-   **`@Get`**: Defines a handler for HTTP GET requests.

    ```dart
    @Get('/path')
    Future<void> getHandler() async {
      // Handler logic
    }
    ```

-   **`@Post`**: Defines a handler for HTTP POST requests.

    ```dart
    @Post('/path')
    Future<void> postHandler(@Body() RequestBody body) async {
      // Handler logic
    }
    ```

-   **`@Put`**: Defines a handler for HTTP PUT requests.

    ```dart
    @Put('/path/{id}')
    Future<void> putHandler(@Param('id') String id, @Body() RequestBody body) async {
      // Handler logic
    }
    ```

-   **`@Delete`**: Defines a handler for HTTP DELETE requests.

    ```dart
    @Delete('/path/{id}')
    Future<void> deleteHandler(@Param('id') String id) async {
      // Handler logic
    }
    ```

-   **`@Body`**: Accesses the request body data.

    ```dart
    Future<void> handler(@Body() RequestBody body) async {
      // Access body parameter
    }
    ```

-   **`@Query`**: Fetches query parameters from the request URL.

    ```dart
    Future<void> handler(@Query('param') String param) async {
      // Access query parameter
    }
    ```

-   **`@Param`**: Retrieves parameters embedded in the request path.

    ```dart
    Future<void> handler(@Param('id') String id) async {
      // Access path parameter
    }
    ```

-   **`@Header`**: Gets values from the request headers.

    ```dart
    Future<void> handler(@Header('Authorization') String auth) async {
      // Access header parameter
    }
    ```

-   **`@WebSocket`**: Defines a handler for WebSocket messages.

    ```dart
    @WebSocket('/ws', mode: WebSocketMode.twoWay)
    Stream<String> onMessage(String message) async* {
      yield 'Echo: $message';
    }
    ```

-   **`@Interceptor`**: Applies pre-processing and post-processing logic to requests.

    ```dart
    @Interceptor()
    class MyInterceptor {
      Future<void> intercept(InterceptorContext context) async {
        await context.next();
      }
    }
    ```

-   **`@Guard`**: Protects routes and allows custom logic for granting or denying requests.

    ```dart
    @Guard()
    class AuthGuard implements CanActivate {
      Future<bool> canActivate(RequestContext context) async {
        return true;
      }
    }
    ```

## Classes and Methods

### Detailed Reference for Core Classes and Methods

-   **`Router`**: Manages route matching and controller invocation.

    ```dart
    final router = Router();
    router.get('/path', handler);
    ```

-   **`AppConfig`**: Base class for defining app configurations, including dependency registration.

    ```dart
    @App(flavor: 'dev')
    class DevApp extends AppConfig {
      @override
      Future<void> configureDependencies(DI di) async {
        di.register<SomeService>(SomeServiceImpl.new);
      }
    }
    ```

-   **`RequestContext`**: Provides access to the request and response objects during the request lifecycle.

    ```dart
    Future<void> handler(RequestContext context) async {
      final request = context.request;
      final response = context.response;
      // Handle request and response
    }
    ```

-   **`Response`**: Represents HTTP responses, including status code, headers, and body.

    ```dart
    final response = Response(200, body: 'Success', headers: {'Content-Type': 'text/plain'});
    ```

Understanding these annotations, classes, and methods will help you leverage Revali's capabilities to build efficient and scalable applications.
