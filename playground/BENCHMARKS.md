# Playground hot-path benchmarks

Release multi-isolate ping against `http://127.0.0.1:8090/api/stress/ping`.

## Method

```bash
# Server (release, multi-isolate via AppConfig.workers)
cd playground
dart run revali dev --flavor dev --release

# Bench (Dart stress client; pass --ab to try ApacheBench)
dart run bin/bench.dart --label <label> --concurrency 300 --duration 15s
```

Fixed settings for this series unless noted: **release**, **workers =
numberOfProcessors**, **mix=ping**, **concurrency=300**, **duration=15s**.

Environment for this series: Apple M2 Max, 12 cores, Dart 3.12.2
(`macos_arm64`), playground on port 8090.

Numbers are single-machine and noisy (±5–10%); compare relative deltas.

| label | RPS | mean ms | p50 ms | p95 ms | p99 ms | failed | tool |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| baseline | 1885 | 159.8 | 160 | 218 | 251 | 0 | stress |
