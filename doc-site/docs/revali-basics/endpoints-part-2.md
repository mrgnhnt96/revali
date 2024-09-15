---
sidebar_position: 3
---

# Endpoints: Part 2

```dart
@Controller('user')
class UserController {
  const UserController({
    required this.userRepository,
  });

  final UserRepository userRepository;

  @Post()
  Future<void> create() async {}

  @Get()
  Future<void> read() async {}

  @Patch() // or @Put()
  Future<void> update() async {}

  @Delete()
  Future<void> delete() async {}
}
```
