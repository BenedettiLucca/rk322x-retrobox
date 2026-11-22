## psx3d-crash-r1

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 88.5 | 89.2 | 89.2 | 89.2 |
| cpu_pct_total | 99.0 | 100.4 | 103.3 | 103.5 |
| rss_kb | 105729.0 | 105700.0 | 106252.0 | 106252.0 |
| cpu0_freq_khz | 1068493 | 1008000 | 1200000 | 1200000 |
| cpu1_freq_khz | 1068493 | 1008000 | 1200000 | 1200000 |
| cpu2_freq_khz | 1071123 | 1008000 | 1200000 | 1200000 |
| cpu3_freq_khz | 1071123 | 1008000 | 1200000 | 1200000 |

Page flips (from strace DRM ioctls): 2220
| metric | value |
|---|---:|
| mean interval ms | 52.52 |
| median interval ms | 40.22 |
| p95 interval ms | 106.01 |
| p99 interval ms | 118.83 |
| implied fps | 19.04 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

