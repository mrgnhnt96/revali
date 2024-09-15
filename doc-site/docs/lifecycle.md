# Lifecycle

## Request Lifecycle

Understanding the request lifecycle in Revali is crucial for effectively managing requests and responses within your application. Here’s an overview of the stages involved:

### 1. Routing

Requests are first matched against registered routes. The `Router` class is responsible for determining if any endpoint corresponds to the incoming request's URI and HTTP method.

### 2. Controllers

Once a route is matched, control is handed over to the corresponding controller. Controllers are classes annotated with `@Controller` and contain methods to handle various HTTP requests (GET, POST, PUT, DELETE):

```dart
@Controller('example')
class ExampleController {
  @Get('/example')
  Future<void> exampleMethod() async {
    // Method logic
  }
}
```

### 3. Request Parameters

During the controller method execution, you can access various request parameters such as body, query, path, and header parameters using annotations like `@Body`, `@Query`, `@Param`, and `@Header`.

### 4. Middleware/Interceptors

Interceptors and middleware are executed around the request handling. These can pre-process requests or post-process responses, handling tasks like authentication, validation, logging, or modifying responses. For example:

```dart
@Interceptor() // Applied before and after the request handler
class MyInterceptor {
  Future<void> intercept(InterceptorContext context) async {
    // Pre-processing logic here
    await context.next();
    // Post-processing logic here
  }
}
```

### 5. Dependency Injection

Revali uses a dependency injection (DI) system to manage the creation and provision of required instances within controllers and other components:

```dart
@App(flavor: 'dev')
class DevApp extends AppConfig {
  @override
  Future<void> configureDependencies(DI di) async {
    di.register<SomeService>(SomeServiceImpl.new);
  }
}
```

### 6. Guards

Guards are used to protect routes and are executed after interceptors but before the actual route handler. They can allow or deny the processing of a request based on custom logic:

```dart
@Guard()
class AuthGuard implements CanActivate {
  @override
  Future<bool> canActivate(RequestContext context) async {
    // Authentication logic
    return true;  // or false to deny access
  }
}
```

### 7. Exception Handling

If any part of the lifecycle throws an exception, it is caught and handled by Revali's exception filters. These filters format the error responses sent back to the client.

### 8. Final Response

After all processing, including any post-handler interceptors or exception filters, the response is finalized and sent back to the client.

### Summary

This structured lifecycle ensures that each part of the request-handling process has a clear and specific role, improving code organization and maintaining separation of concerns.

Here’s a summarized sequence:

1. **Routing**: Match request to route.
2. **Controller Handling**: Invoke the relevant controller method.
3. **Request Parameters**: Access body, query, path, and header parameters.
4. **Middleware/Interceptors**: Pre-process and post-process requests.
5. **Dependency Injection**: Provide necessary dependencies.
6. **Guards**: Protect routes with custom logic.
7. **Exception Handling**: Catch and handle exceptions.
8. **Final Response**: Send the response back to the client.
