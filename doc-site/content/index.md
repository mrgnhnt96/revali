---
title: Revali
description: A modern, fast, and powerful Dart API framework.
---

<!-- The opening tag has to stay on one line, and the attribute names have to
     stay lowercase/hyphenated. See lib/components/cards.dart's Hero. -->
<Hero headline="Build powerful APIs with Dart" tagline="Revali reads the annotations on your classes and methods and generates the server, the client, and the OpenAPI document. You write the business logic." primary-label="Get Started" primary-href="/revali/getting-started/installation" secondary-label="View on GitHub" secondary-href="https://github.com/mrgnhnt96/revali">

<!-- Keep every line under ~48 characters. The hero code column is narrow, and
     anything longer scrolls sideways in the one place nobody expects to. -->

```dart
@Controller('users')
class UserController {
  const UserController(this.users);

  final UserService users;

  @Get()
  Future<List<User>> all() => users.all();

  @Post()
  Future<User> create(@Body() UserInput input) {
    return users.create(input);
  }
}
```

</Hero>

<SectionCards />

## Why Revali

<CardGrid columns="3">

<Card title="Highly extendable" icon="blocks">

Constructs are first-class. Generate a Dart client, a Swagger document or a
Dockerfile from the same annotations — or [write your own](/create-constructs).

</Card>

<Card title="Rapid development" icon="rocket">

`revali dev` watches your routes, regenerates the server and hot reloads it.
No build step to remember, no restart to sit through.

</Card>

<Card title="Powered by Dart" icon="dart">

One language across your API and your Flutter app, with the same types on both
sides of the wire and no hand-written serialization in between.

</Card>

</CardGrid>

## Where to start

<CardGrid columns="2">

<Card title="Install Revali" href="/revali/getting-started/installation" icon="rocket">

Add the CLI to a Dart project and get a server answering requests.

</Card>

<Card title="Create your first endpoint" href="/revali/getting-started/create-your-first-endpoint" icon="terminal">

Write a controller, annotate a method, and watch the route appear.

</Card>

<Card title="Understand the request lifecycle" href="/constructs/revali_server/lifecycle-components" icon="server">

Middleware, guards, interceptors and exception catchers, and the order they run in.

</Card>

<Card title="Generate a typed client" href="/constructs/revali_client" icon="plug">

Call your API from Flutter with the same models the server returns.

</Card>

</CardGrid>
