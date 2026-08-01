# Revali

Revali is a powerful code generator specifically designed for APIs. By leveraging annotations within your classes, methods, and method parameters, Revali manages the boilerplate code for you, allowing you to focus on writing clean and maintainable code.

## Creating a Controller

Here's a quick example of how to create a controller using Revali:

```dart
import 'package:revali_router/revali_router.dart';

@Controller("example")
class ExampleController {
  @Get('items')
  Future<List<String>> getItems() async {
    return ['item1', 'item2', 'item3'];
  }

  @Post('items')
  Future<void> createItem(@Body() Map<String, String> item) async {
    print('New item added: ${item['name']}');
  }
}
```

To learn more about how Revali can help simplify your backend development workflow, including advanced topics like dependency injection, WebSocket management, and custom middleware, please visit [revali.dev](https://revali.dev) for the full documentation.

## CLI

```bash
dart run revali --help

dart run revali dev [--inspect] [--skip-if-fresh] [--recompile]
dart run revali routes [--generate] [--json]   # .revali/server/routes.json
dart run revali doctor [--json]
dart run revali create controller|app|lifecycle-component|pipe|observer
```

`create` proxies to `dart run revali_server create` (scaffolds still live in `revali_server`).

Missing / invalid request bindings raise `MissingArgumentException` and map to **HTTP 400**. Prefer `LifecycleComponent` for new middleware; `@RequestId()` is available as a built-in kit.

## Agents & MCP

- Contributor / agent conventions: [AGENTS.md](./AGENTS.md)
- Cursor skill: [`.cursor/skills/revali`](./.cursor/skills/revali/SKILL.md)
- Stdio MCP server: [`packages/revali_mcp`](./packages/revali_mcp) (`list_routes`, `get_route`, `doctor`, `recent_requests`, `create_scaffold`)

## Contributing

We welcome contributions!

## Developer Information

To assist with development tasks, you can use the `sip_cli` pub package to run various scripts defined in the `scripts.yaml` file. This is similar to using the `scripts` section in a `package.json` file for Node.js projects. These scripts simplify common development tasks, such as code generation and building packages.

### Available Scripts

Please refer to the [scripts.yaml](./scripts.yaml) file directly for an up to date listing of all commands.

## License

Revali is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
