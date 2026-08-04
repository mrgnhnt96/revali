# Revali

Revali is a powerful code generator specifically designed for the Dart programming language. It leverages annotations within your classes, methods, and method parameters to create an API, allowing developers to focus on writing clean, maintainable code while it handles the boilerplate.

Revali analyzes your Dart classes, methods, and annotations to generate your server code — built in, no extra package needed. Additional "constructs" (client generation, OpenAPI docs, Docker, or your own) are standalone dart packages you import into your project; Revali picks them up and runs them to generate more code alongside the server.

## Example

```dart
@Controller('hello')
class HelloController {
  const HelloController();

  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
```

## CLI

```bash
dart run revali dev
dart run revali routes [--generate] [--json]
dart run revali doctor
dart run revali create controller
```

See the [root README](../../README.md) and [AGENTS.md](../../AGENTS.md) for routes/doctor/create, HTTP 400 binding errors, `@RequestId()`, and the `revali_mcp` agent server.

## Documentation

Check out the [documentation](https://www.revali.dev/) for more information on how to use Revali.
