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

Absolute RPS is noisy under multi-isolate load. Prefer nearby comparisons;
outliers are marked. Best “after all” estimate uses the dual-run median for
item 5.

## Results (in apply order)

| label | RPS | mean ms | p50 ms | p95 ms | p99 ms | failed | tool | notes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| baseline | 1885 | 159.8 | 160 | 218 | 251 | 0 | stress | pre hot-path |
| 4-single-find | 2525 | 123.4 | 97 | 211 | 947 | 0 | stress | after item 4 |
| 6-static-route-map | 18255 | 16.4 | 12 | 34 | 105 | 0 | stress | **outlier** (high) |
| 6-recheck | 9964 | 30.0 | 23 | 66 | 149 | 0 | stress | same code as 6, later |
| 2-body-byte-cache | 13476 | 22.2 | 19 | 40 | 104 | 0 | stress | after item 2 vs 6-recheck |
| 3-empty-lifecycle | 9113 | 32.9 | 26 | 69 | 142 | 0 | stress | noisy; within variance |
| 5-headers-r1 | 23727 | 12.6 | 12 | 18 | 30 | 0 | stress | after item 5 |
| 5-headers-r2 | 26486 | 11.3 | 11 | 14 | 23 | 0 | stress | after item 5 |

## Summary

| milestone | ~RPS | Δ vs baseline |
| --- | ---: | ---: |
| baseline | 1885 | — |
| + single Find (4) | 2525 | +34% |
| + static route map (6) | ~10k (recheck) | ~5.3× |
| + body byte cache (2) | ~13.5k | ~7.1× |
| + empty lifecycle (3) | noisy (~9k) | structural |
| + headers/date/backlog (5) | ~25k (median) | ~13× |

Net: release ping moved from **~1.9k → ~25k RPS** (~13×) on this machine.
