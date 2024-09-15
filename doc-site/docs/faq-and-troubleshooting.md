# FAQ and Troubleshooting

## FAQ

### Common Questions and Answers

**Q: What is Revali and how does it work?**

A: Revali is a code generator for the Dart programming language that uses annotations to create APIs, helping developers focus on writing maintainable code while it handles the boilerplate.

**Q: How do I install Revali?**

A: Add `revali_router` to your `dependencies` and `revali` and `revali_server` to your `dev_dependencies` in your `pubspec.yaml`.

**Q: How do I access request parameters in Revali?**

A: Use specific annotations such as `@Body` for body parameters, `@Query` for query parameters, `@Param` for path parameters, and `@Header` for header parameters.

**Q: What are guards and how do I use them?**

A: Guards are used to protect routes and run before the request reaches the controller. Implement the `CanActivate` interface and register the guard with the `@UseGuards` annotation.

## Troubleshooting

### Solving Common Issues

**Issue: My routes are not being matched properly.**

-   Check that your controller methods have the correct HTTP method annotations, such as `@Get`, `@Post`, etc.
-   Ensure that the URL paths are correctly defined and match the incoming request paths.

**Issue: Dependency injection is not working as expected.**

-   Verify that dependencies are correctly registered in the `AppConfig` class.
-   Ensure that the dependencies are being correctly injected into your controllers.

**Issue: WebSocket connection is not being established.**

-   Ensure that the WebSocket endpoint is correctly defined with the `@WebSocket` annotation.
-   Verify that the WebSocket handler is registered in your `AppConfig`.

## Feedback and Roadmap

### Reporting Issues

If you encounter any issues, you can report them on the Revali GitHub repository. Include a detailed description of the problem and any relevant code or error messages.

### Feature Requests

We welcome feature requests from the community. Submit your ideas or enhancements via the GitHub Issues page or through our feedback portal.

Stay updated with the latest developments and roadmap of Revali by following our project on GitHub and joining our community discussions.
