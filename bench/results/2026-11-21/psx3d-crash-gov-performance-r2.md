## psx3d-crash-gov-performance-r2

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 89.7 | 90.0 | 90.0 | 91.0 |
| cpu_pct_total | 99.1 | 100.6 | 103.3 | 103.6 |
| rss_kb | 105714.4 | 105684.0 | 106236.0 | 106236.0 |
| cpu0_freq_khz | 1010630 | 1008000 | 1008000 | 1200000 |
| cpu1_freq_khz | 1010630 | 1008000 | 1008000 | 1200000 |
| cpu2_freq_khz | 1010630 | 1008000 | 1008000 | 1200000 |
| cpu3_freq_khz | 1010630 | 1008000 | 1008000 | 1200000 |

Page flips (from strace DRM ioctls): 2216
| metric | value |
|---|---:|
| mean interval ms | 52.76 |
| median interval ms | 40.69 |
| p95 interval ms | 105.91 |
| p99 interval ms | 118.32 |
| implied fps | 18.95 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

