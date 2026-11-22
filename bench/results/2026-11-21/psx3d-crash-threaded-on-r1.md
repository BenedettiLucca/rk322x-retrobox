## psx3d-crash-threaded-on-r1

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 88.6 | 88.3 | 89.2 | 90.0 |
| cpu_pct_total | 107.2 | 109.7 | 112.4 | 112.6 |
| rss_kb | 110853.2 | 111116.0 | 111300.0 | 111804.0 |
| cpu0_freq_khz | 1004952 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 3224
| metric | value |
|---|---:|
| mean interval ms | 36.02 |
| median interval ms | 33.30 |
| p95 interval ms | 56.21 |
| p99 interval ms | 67.42 |
| implied fps | 27.76 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

