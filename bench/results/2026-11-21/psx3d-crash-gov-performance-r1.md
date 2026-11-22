## psx3d-crash-gov-performance-r1

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 88.0 | 88.3 | 89.2 | 89.2 |
| cpu_pct_total | 98.9 | 100.5 | 103.2 | 103.4 |
| rss_kb | 105715.4 | 105688.0 | 106232.0 | 106232.0 |
| cpu0_freq_khz | 1094795 | 1008000 | 1200000 | 1200000 |
| cpu1_freq_khz | 1097425 | 1008000 | 1200000 | 1200000 |
| cpu2_freq_khz | 1097425 | 1008000 | 1200000 | 1200000 |
| cpu3_freq_khz | 1102685 | 1008000 | 1200000 | 1200000 |

Page flips (from strace DRM ioctls): 2231
| metric | value |
|---|---:|
| mean interval ms | 52.32 |
| median interval ms | 40.63 |
| p95 interval ms | 106.76 |
| p99 interval ms | 118.73 |
| implied fps | 19.11 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

