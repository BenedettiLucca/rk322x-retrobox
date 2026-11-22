## psx3d-crash-spuoff-r3

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 85.0 | 85.0 | 85.8 | 87.5 |
| cpu_pct_total | 112.2 | 114.7 | 117.6 | 118.0 |
| rss_kb | 110213.1 | 110056.0 | 110556.0 | 110556.0 |
| cpu0_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1005474 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 1028
| metric | value |
|---|---:|
| mean interval ms | 112.81 |
| median interval ms | 43.92 |
| p95 interval ms | 266.64 |
| p99 interval ms | 303.39 |
| implied fps | 8.86 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

