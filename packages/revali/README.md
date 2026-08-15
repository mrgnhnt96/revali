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
dart run revali build
dart run revali routes [--generate] [--json]
dart run revali doctor
dart run revali create controller
dart run revali ai <claude|cursor|copilot|windsurf|cline|all>

# Repositories with more than one service
dart run revali services
dart run revali up
dart run revali compose
```

`revali up` runs every service in the repository together — a roster, a log
pane per service, and keys that drive one of them or all of them — falling back
to flat prefixed output where there is no terminal. See
[`revali up`](https://www.revali.dev/revali/cli/up).

See the [root README](https://github.com/mrgnhnt96/revali#readme) and
[AGENTS.md](https://github.com/mrgnhnt96/revali/blob/main/AGENTS.md) for
routes/doctor/create, HTTP 400 binding errors, `@RequestId()`, and the
`revali_mcp` agent server.

## Documentation

Check out the [documentation](https://www.revali.dev/) for more information on how to use Revali.
