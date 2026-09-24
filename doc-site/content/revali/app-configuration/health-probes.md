---
title: Health Probes
description: Liveness and readiness endpoints for orchestrators, and how to add readiness checks
---

Every Revali server answers two probe endpoints by default. Point your orchestrator's probes at them. When you need readiness to depend on something, such as a database, add readiness checks.

| Path | Question | A failure means |
| --- | --- | --- |
| `GET /healthz` | Is the process alive? | Restart it |
| `GET /readyz` | Should traffic come here? | Route traffic elsewhere and leave the process running |

- **Probes are served outside `prefix`.** They answer at `/healthz`, not `/api/healthz`.
- **Liveness never runs checks.** If a database outage failed liveness, the orchestrator would restart every instance at once.
- **During shutdown, liveness keeps returning `200`**, while readiness returns `503 {"status":"draining"}` without running any checks. See [Graceful Shutdown](/revali/app-configuration/graceful-shutdown).

## Responses

```json
{ "status": "ok" }
```

With checks registered, readiness names each one, and any failure makes the response `503`:

```json
{
  "status": "unhealthy",
  "checks": {
    "database": { "status": "ok" },
    "queue": { "status": "unhealthy", "detail": "broker down" }
  }
}
```

## Readiness Checks

<CodeFile name="lib/health/database_is_reachable.dart">

```dart
import 'package:revali_router/revali_router.dart';

class DatabaseIsReachable implements HealthCheck {
  const DatabaseIsReachable(this.db);

  final Database db;

  @override
  String get name => 'database'; // the key in the response body

  @override
  Future<HealthCheckResult> check() async {
    try {
      await db.ping();
      return const HealthCheckResult.healthy();
    } catch (e) {
      return HealthCheckResult.unhealthy('$e');
    }
  }
}
```

</CodeFile>

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:my_app/health/database_is_reachable.dart';
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  MainApp() : super.fromEnv();

  final db = Database.connect(Env.current.require('DATABASE_URL'));

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerSingleton<Database>(db);
  }

  @override
  HealthSettings get health => HealthSettings(
        checks: [DatabaseIsReachable(db)],
        checkTimeout: const Duration(seconds: 2),
      );
}
```

</CodeFile>

How checks behave:

- **Checks run concurrently.** A probe takes as long as its slowest check.
- **A check that throws or times out counts as unhealthy**, with the error as its `detail`. It never causes a 500.
- **`detail` is visible to anyone who can reach the pod**, so never put credentials in it.
- **Only add checks for dependencies the service can't work without.** If a cache the service can do without becomes a check, one slow cache node takes every instance out of rotation.

## `HealthSettings`

| Field | Default | Description |
| --- | --- | --- |
| `livenessPath` | `'/healthz'` | `null` turns liveness off. |
| `readinessPath` | `'/readyz'` | `null` turns readiness off. |
| `checks` | `[]` | The checks readiness runs. |
| `checkTimeout` | 5 seconds | How long one check can run before it counts as unhealthy. Keep it below the orchestrator's probe timeout. `Duration.zero` turns the timeout off. |

`const HealthSettings.disabled()` turns off both probes. A path that's turned off returns `404`.

## Kubernetes

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
readinessProbe:
  httpGet:
    path: /readyz
    port: 8080
    timeoutSeconds: 10 # above checkTimeout
```
