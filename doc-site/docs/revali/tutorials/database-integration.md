---
sidebar_position: 4
description: Connect to your data layer with a repository and DI
---

# Database Integration

This tutorial connects an endpoint to a real database using [`sqlite3`](https://pub.dev/packages/sqlite3), registered through Revali's [dependency injection][configure-dependencies]. The same repository pattern applies to any database driver (Postgres, MySQL, etc.) -- swap the driver-specific calls inside the repository and everything else stays the same.

## Add the driver

```yaml title="pubspec.yaml"
dependencies:
  sqlite3: ^2.9.0
```

## Write a repository

The repository owns all database-specific code. Nothing outside it needs to know it's backed by SQLite:

```dart title="lib/repos/todo_repository.dart"
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

## Register the connection and repository

Open the database once and register both it and the repository as lazy singletons in `configureDependencies`. Because `TodoRepository`'s constructor takes a dependency, register it with a closure that resolves `Database` from `di` -- a bare `TodoRepository.new` tear-off only works for constructors that take no arguments:

```dart title="routes/main_app.dart"
import 'package:revali_router/revali_router.dart';
import 'package:sqlite3/sqlite3.dart';

import '../lib/repos/todo_repository.dart';

@App()
final class MainApp extends AppConfig {
  MainApp() : super(host: 'localhost', port: 8080);

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

:::tip
`sqlite3.openInMemory()` is used here so the tutorial has zero setup -- the database lives for the life of the server process. For a persisted database, use `sqlite3.open('path/to/file.db')` instead; everything else in this tutorial is unchanged.
:::

## Inject the repository into a controller

Controller constructor parameters are resolved from DI automatically. Mark them with `@Dep()`:

```dart title="routes/controllers/todo_controller.dart"
import 'package:revali_router/revali_router.dart';

import '../../lib/repos/todo_repository.dart';

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

`POST /todos` with body `{"title": "Buy milk"}` inserts a row and returns `{"id": 1, "title": "Buy milk"}`. `GET /todos` lists every row inserted so far -- the same `Database` instance is reused across requests because it's registered as a lazy singleton, not recreated per request.

## What's next?

- [Configure Dependencies][configure-dependencies] — registration methods (`registerSingleton`, `registerFactory`, `registerLazySingleton`), the `Inject` marker for DI values inside annotations, and request-scoped dependencies for per-request state like transactions
- [Body](/constructs/revali_server/request/body) — binding and validating request bodies beyond a single field

[configure-dependencies]: /revali/app-configuration/configure-dependencies
