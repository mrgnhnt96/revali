---
title: Overview
description: Generate an OpenAPI 3.0.3 spec from your Revali routes, then install and configure revali_swagger
---

`revali_swagger` generates an [OpenAPI 3.0.3](https://spec.openapis.org/oas/v3.0.3) spec from your controllers, parameters and return types. Use it to feed Swagger UI, Redoc, API gateways or client generators for languages other than Dart. For a Dart client, use [revali_client](/constructs/revali_client) instead.

It is a generic construct, so the spec is rewritten on every `revali dev` (and `revali build`) run.

## Installation

| Package | Role | Section |
| --- | --- | --- |
| `revali_swagger` | The construct (spec generator) | `dev_dependencies` |
| `revali_swagger_annotations` | Optional [annotations](/constructs/revali_swagger/annotations) (`@ApiSummary`, `@ApiTag`, ...) | `dependencies` |

```bash
dart pub add --dev revali_swagger
dart pub add revali_swagger_annotations # only if you use the annotations
```

<CodeFile name="pubspec.yaml">

```yaml
dependencies:
  revali_swagger_annotations: ^1.0.0

dev_dependencies:
  revali: ^3.3.3
  revali_swagger: ^1.3.0
```

</CodeFile>

No `revali.yaml` entry is required. Run:

```bash
dart run revali dev
```

The spec is written in both formats:

```tree
.revali/revali_swagger/
├── swagger.yaml
└── swagger.json
```

Types the generator cannot map are reported on stderr as `[revali_swagger] WARNING: ...`. Fix them with [`@ApiType`](/constructs/revali_swagger/annotations#apitype).

## Configuration

All options are optional and go under the construct's entry in `revali.yaml`:

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_swagger
    options:
      title: My API
      version: 2.1.0
      description: Public API for the My App service
```

</CodeFile>

| Option | Type | Default | Sets |
| --- | --- | --- | --- |
| `title` | `String` | `API` | `info.title` |
| `version` | `String` | `1.0.0` | `info.version` |
| `description` | `String` | none | `info.description` |

[`@ApiInfo`](/constructs/revali_swagger/annotations#apiinfo) on your app class overrides these values.

## Example

<CodeFile name="routes/controllers/users_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController();

  @Get(':id')
  Future<User> getById(@Param() String id) async => ...;

  @Post()
  @StatusCode(201)
  Future<User> create(@Body() CreateUserBody body) async => ...;
}
```

</CodeFile>

produces (abridged):

<CodeFile name=".revali/revali_swagger/swagger.yaml">

```yaml
openapi: 3.0.3
info:
  title: API
  version: 1.0.0
paths:
  '/users':
    post:
      operationId: users_create
      tags:
        - users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserBody'
      responses:
        '201':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
  '/users/{id}':
    get:
      operationId: users_getById
      tags:
        - users
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
components:
  schemas:
    # User, CreateUserBody ...
```

</CodeFile>

## How routes map to the spec

- **Paths** join the controller and method paths, with `:id` rewritten as `{id}`. The app prefix (`/api` by default) is **not** included, and the spec has no `servers` block. Add both in your tooling if it needs them.
- **Operation IDs** are `<controller>_<method>`, where `<controller>` is the class name without `Controller`, lowercased: `UsersController.getById` becomes `users_getById`.
- **Tags** default to that same lowercased controller name. Override them with [`@ApiTag`](/constructs/revali_swagger/annotations#apitag).
- **Parameters**: `@Param` becomes `in: path`, `@Query` `in: query`, `@Header` `in: header`, `@Cookie` `in: cookie`. `@Body` becomes the `requestBody`, except on `GET`, `HEAD` and `DELETE`, where it is documented as a query parameter.
- **Responses** use the method's `@StatusCode`, or `200`. A `void` handler gets a `No content` response with no schema. [`@ApiResponse`](/constructs/revali_swagger/annotations#apiresponse) replaces this default.
- **Response schemas** describe the handler's return type as-is. They do not include the `{"data": ...}` envelope that Revali wraps JSON responses in.
- **Output** is sorted by path and method, so the spec is stable across machines and safe to commit or diff.

See [Type Inference](/constructs/revali_swagger/type-inference) for how Dart types become schemas, and [Annotations](/constructs/revali_swagger/annotations) to add summaries, descriptions and extra responses.
