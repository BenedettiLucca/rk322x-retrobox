## psx3d-crash-gov-performance-r3

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 90.0 | 90.0 | 90.0 | 91.0 |
| cpu_pct_total | 99.0 | 100.5 | 103.2 | 103.4 |
| rss_kb | 105655.0 | 105632.0 | 106184.0 | 106184.0 |
| cpu0_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 2207
| metric | value |
|---|---:|
| mean interval ms | 52.86 |
| median interval ms | 41.05 |
| p95 interval ms | 105.41 |
| p99 interval ms | 117.99 |
| implied fps | 18.92 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

