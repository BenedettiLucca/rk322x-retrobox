## psx3d-crash-vsync-off-r3

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 86.8 | 86.7 | 87.5 | 88.3 |
| cpu_pct_total | 96.0 | 97.0 | 99.5 | 99.7 |
| rss_kb | 105673.1 | 105564.0 | 106312.0 | 106312.0 |
| cpu0_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 1657
| metric | value |
|---|---:|
| mean interval ms | 69.91 |
| median interval ms | 72.57 |
| p95 interval ms | 123.50 |
| p99 interval ms | 139.53 |
| implied fps | 14.31 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

