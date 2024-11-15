# Revali

Revali is a powerful code generator specifically designed for the Dart programming language. It leverages annotations within your classes, methods, and method parameters to create an API, allowing developers to focus on writing clean, maintainable code while it handles the boilerplate.

Revali analyzes your Dart classes, methods, and annotations to generate code provided by "constructs". These constructs are standalone dart packages that are imported into your project, picked up by Revali, and used to generate code.

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

## Documentation

Check out the [documentation](https://www.revali.dev/) for more information on how to use Revali.
