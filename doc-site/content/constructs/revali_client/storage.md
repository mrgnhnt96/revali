---
title: Storage & Cookies
description: How the generated client stores cookies, and how to persist them across app restarts with a custom Storage
---

The generated client keeps cookies in a `Storage`. By default this is `SessionStorage`, an in-memory map that is lost when the app exits. Pass your own `Storage` to `Server` to keep a login session across restarts.

## What the client stores

- **Cookies from responses.** Every `Set-Cookie` header on a successful response is parsed and saved with `saveAll`, one key per cookie name.
- **Cookies for requests.** An endpoint with `@Cookie('name')` parameters sends those cookies in a `Cookie` header, read from storage by name. A required cookie that is not in storage throws before the request is sent. Endpoints without `@Cookie` parameters send no `Cookie` header.
- **`__BASE_URL__`.** `Server` saves the base URL it was built with under this key.

See [Cookies](/constructs/revali_server/response/cookies) for the server side.

## The `Storage` interface

```dart
abstract interface class Storage {
  Future<Object?> operator [](String key);
  Future<void> save(String key, Object? value);
  Future<void> saveAll(Map<String, Object?> values);
  Future<void> remove(String key);
  Future<void> clear();
}
```

`save(key, null)` should remove the key, which is what `SessionStorage` does.

## Persistent storage

A `shared_preferences` implementation for Flutter:

<CodeFile name="lib/prefs_storage.dart">

```dart
import 'package:revali_client/revali_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsStorage implements Storage {
  PrefsStorage(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<Object?> operator [](String key) => _prefs.getString(key);

  @override
  Future<void> save(String key, Object? value) async {
    if (value == null) return _prefs.remove(key);

    await _prefs.setString(key, '$value');
  }

  @override
  Future<void> saveAll(Map<String, Object?> values) async {
    for (final MapEntry(:key, :value) in values.entries) {
      await save(key, value);
    }
  }

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> clear() => _prefs.clear();
}
```

</CodeFile>

```dart
final server = Server(storage: PrefsStorage(SharedPreferencesAsync()));
```

Return cookie values as `String`. The client skips an optional cookie whose stored value is not a `String`.

## Web builds and cross-origin cookies

On the web, `HttpPackageClient` turns on `withCredentials` so the browser also sends and accepts cookies on cross-origin requests. That only works if the server's CORS response allows credentials for your frontend's exact origin: a specific `Access-Control-Allow-Origin` (not `*`) plus `Access-Control-Allow-Credentials: true`. See [Allow Origins](/constructs/revali_server/access-control/allow-origins).
