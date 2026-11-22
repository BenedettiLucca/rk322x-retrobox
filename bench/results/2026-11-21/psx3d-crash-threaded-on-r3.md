## psx3d-crash-threaded-on-r3

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 158s
- Frames/s wall (includes startup): 6329.108

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 88.9 | 89.2 | 89.2 | 89.2 |
| cpu_pct_total | 106.3 | 108.7 | 111.4 | 111.6 |
| rss_kb | 110871.7 | 111156.0 | 111340.0 | 111844.0 |
| cpu0_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 3189
| metric | value |
|---|---:|
| mean interval ms | 36.43 |
| median interval ms | 34.20 |
| p95 interval ms | 56.02 |
| p99 interval ms | 65.72 |
| implied fps | 27.45 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

