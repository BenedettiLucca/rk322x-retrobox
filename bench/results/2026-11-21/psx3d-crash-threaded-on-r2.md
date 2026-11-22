## psx3d-crash-threaded-on-r2

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 88.8 | 89.2 | 89.2 | 89.2 |
| cpu_pct_total | 106.9 | 109.3 | 112.1 | 112.4 |
| rss_kb | 110859.5 | 111128.0 | 111312.2 | 111816.0 |
| cpu0_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 3207
| metric | value |
|---|---:|
| mean interval ms | 36.25 |
| median interval ms | 34.04 |
| p95 interval ms | 54.83 |
| p99 interval ms | 63.79 |
| implied fps | 27.59 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

