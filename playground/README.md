# Playground — stress harness for Revali

Minimal Revali app used to overload the server and find weak points.

## Run the server

```bash
cd playground
dart pub get
dart run revali dev --flavor dev
```

Serves at `http://127.0.0.1:8090/api/stress/...`

Uses `AppConfig.workers = Platform.numberOfProcessors` so connections are
accepted across multiple isolates (`HttpServer.bind(..., shared: true)`).

## Stress

```bash
dart run bin/stress.dart --concurrency 200 --duration 20s --mix ping
dart run bin/stress.dart --concurrency 150 --duration 15s --mix heavy
dart run bin/stress.dart --concurrency 100 --duration 10s --mix all
```

Mixes: `ping`, `delay`, `error`, `heavy`, `all`.

## Hot reload churn

With `revali dev --flavor dev` running:

```bash
./bin/churn_hot_reload.sh   # add/remove controllers, broken→fixed
./bin/churn_ai_ready.sh     # parallel AI-style writes + .revali_cmd hotkeys
```

Headless reload (no TTY): write `r`, `c`, or `q` to `.revali_cmd` in the
playground root.

## Bench (stable ping RPS)

```bash
dart run bin/bench.dart --label baseline --concurrency 300 --duration 15s
```

Results are tracked in [BENCHMARKS.md](BENCHMARKS.md).
