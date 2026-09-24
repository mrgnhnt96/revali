---
title: Overview
description: What Revali is, what a project needs, and how annotated classes become a running server.
---

Revali is a Dart framework for HTTP APIs. You write annotated controller
classes; Revali generates the server code from them and runs it. Optional
[constructs](/constructs) generate more from the same annotations: a typed
Dart client, an OpenAPI document, a Dockerfile.

## At a glance

| | |
| --- | --- |
| **Requires** | Dart SDK 3.8+ |
| **Packages** | `revali_router` (dependency), `revali` (dev dependency) |
| **Your code** | Controllers and apps in `routes/`; everything else in `lib/` |
| **Generated code** | `.revali/`, never edited by hand |
| **Run** | `dart run revali dev`, serving at `http://localhost:8080/api` |
| **Ship** | `dart run revali build` |

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController(this.users);

  final UserService users;

  @Get(':id')
  Future<User> find(@Param() String id) => users.find(id);

  @Post()
  Future<User> create(@Body() User user) => users.create(user);
}
```

That controller serves `GET /api/users/:id` and `POST /api/users`, with the
path parameter and body parsed, validated and injected. `UserService` comes
from [dependency injection](/revali/app-configuration/configure-dependencies).

## How it works

1. `revali dev` or `revali build` analyzes the files in `routes/`.
2. The built-in server construct generates routing code into `.revali/server/`.
   Any other constructs you depend on generate their own output alongside it.
3. The generated server runs on `revali_router`. In `dev` it restarts
   whenever a file changes.

## Conventions

- **URLs** are `/{prefix}/{controller path}/{method path}`. The prefix defaults
  to `api`. Method names are never part of the URL.
- **Responses:** return values are JSON wrapped as `{"data": ...}`. Return
  `StringContent` or set `response.body` to send something else.
- **Bad input:** a missing or invalid bound parameter is answered with
  `400 Bad Request` before your method runs.
- **Cross-cutting logic** (auth, logging, error mapping) goes in
  [lifecycle components](/constructs/revali_server/lifecycle-components) in
  `lib/components/`.

## Start here

1. [Installation](/revali/getting-started/installation)
2. [Create your first endpoint](/revali/getting-started/create-your-first-endpoint)
3. [Run the server](/revali/getting-started/run-the-server)

Then, as you need them: [app configuration](/revali/app-configuration),
[testing](/revali/testing), the [server reference](/constructs/revali_server),
and, for systems with several services, [messaging](/revali/messaging),
[`revali up`](/revali/cli/up) and [`revali compose`](/revali/cli/compose).

<Callout type="tip">

Using an AI coding assistant? [`dart run revali ai`](/revali/cli/ai) installs a
Revali reference file for it, and the whole site is indexed for LLMs at
[docs.revali.dev/llms.txt](https://docs.revali.dev/llms.txt).

</Callout>
