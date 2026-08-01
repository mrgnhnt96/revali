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

Absolute RPS is noisy under multi-isolate load (±20%+ across runs). Prefer
deltas measured close together; outliers are marked.

| label | RPS | mean ms | p50 ms | p95 ms | p99 ms | failed | tool | notes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| baseline | 1885 | 159.8 | 160 | 218 | 251 | 0 | stress | pre hot-path |
| 4-single-find | 2525 | 123.4 | 97 | 211 | 947 | 0 | stress | after item 4 |
| 6-static-route-map | 18255 | 16.4 | 12 | 34 | 105 | 0 | stress | **outlier** (high) |
| 6-recheck | 9964 | 30.0 | 23 | 66 | 149 | 0 | stress | same code as 6, later |
| 2-body-byte-cache | 13476 | 22.2 | 19 | 40 | 104 | 0 | stress | after item 2 vs 6-recheck |
