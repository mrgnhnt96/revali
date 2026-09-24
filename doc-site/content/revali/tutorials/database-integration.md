---
title: Database Integration
description: Connect to your data layer with a repository and DI
---

In this tutorial you connect endpoints to a database with [`sqlite3`](https://pub.dev/packages/sqlite3). You register the connection and a repository through [dependency injection][configure-dependencies]. The pattern works the same with any driver (Postgres, MySQL and others): only the code inside the repository changes. The examples assume your package is named `my_app`.

## Add the driver

<CodeFile name="pubspec.yaml">

```yaml
dependencies:
  sqlite3: ^2.9.0
```

</CodeFile>

## Write a repository

The repository holds all of the database-specific code:

<CodeFile name="lib/repos/todo_repository.dart">

```dart
import 'package:sqlite3/sqlite3.dart';

class TodoRepository {
  TodoRepository(this._db) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL
      );
    ''');
  }

  final Database _db;

  List<Map<String, Object?>> findAll() {
    final result = _db.select('SELECT id, title FROM todos ORDER BY id');

    return [
      for (final row in result) {'id': row['id'], 'title': row['title']},
    ];
  }

  int insert(String title) {
    _db.execute('INSERT INTO todos (title) VALUES (?)', [title]);
    return _db.lastInsertRowId;
  }
}
```

</CodeFile>

## Register the connection and repository

Register the database and the repository as lazy singletons, so each is created once, the first time it's used. `TodoRepository`'s constructor takes an argument, so register it with a closure that calls `di.get<Database>()`:

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:my_app/repos/todo_repository.dart';
import 'package:revali_router/revali_router.dart';
import 'package:sqlite3/sqlite3.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di
      ..registerLazySingleton<Database>(sqlite3.openInMemory)
      ..registerLazySingleton<TodoRepository>(
        () => TodoRepository(di.get<Database>()),
      );
  }
}
```

</CodeFile>

`sqlite3.openInMemory()` needs no setup, and the data lasts only as long as the server process. To keep the data on disk, use `sqlite3.open('todos.db')` instead.

## Inject the repository into a controller

Revali resolves controller constructor parameters from DI automatically. `@Dep()` is optional here:

<CodeFile name="routes/controllers/todo_controller.dart">

```dart
import 'package:my_app/repos/todo_repository.dart';
import 'package:revali_router/revali_router.dart';

@Controller('todos')
class TodoController {
  const TodoController({@Dep() required this.repo});

  final TodoRepository repo;

  @Get()
  List<Map<String, Object?>> list() => repo.findAll();

  @Post()
  Map<String, Object?> create(@Body(['title']) String title) {
    final id = repo.insert(title);
    return {'id': id, 'title': title};
  }
}
```

</CodeFile>

```bash
curl -X POST http://localhost:8080/api/todos -H 'Content-Type: application/json' -d '{"title": "Buy milk"}'
# {"data":{"id":1,"title":"Buy milk"}}

curl http://localhost:8080/api/todos
# {"data":[{"id":1,"title":"Buy milk"}]}
```

`@Body(['title'])` reads the `title` field from the JSON body. If it's missing, the request gets a 400. Every request uses the same `Database`, because it's a singleton.

Next: [Configure Dependencies][configure-dependencies] (including request-scoped transactions) · [Body binding](/constructs/revali_server/request/body) · [Testing](/revali/testing)

[configure-dependencies]: /revali/app-configuration/configure-dependencies
