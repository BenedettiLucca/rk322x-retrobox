## psx2d-parappa-r1

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 0)
- Requested frames: 999999
- Elapsed: 91s
- Frames/s wall (includes startup): 10989.0

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 90.3 | 90.0 | 91.0 | 91.0 |
| cpu_pct_total | 83.9 | 83.9 | 87.1 | 87.3 |
| rss_kb | 104036.7 | 104176.0 | 104176.0 | 104176.0 |
| cpu0_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 1195
| metric | value |
|---|---:|
| mean interval ms | 44.19 |
| median interval ms | 39.99 |
| p95 interval ms | 84.02 |
| p99 interval ms | 118.79 |
| implied fps | 22.63 |

RA log tail:
```
selected sound output driver: libretro
ari64_reset
```

