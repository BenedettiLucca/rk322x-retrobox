## psx3d-crash-vsync-off-r1

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 158s
- Frames/s wall (includes startup): 6329.108

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 86.7 | 86.7 | 87.5 | 88.3 |
| cpu_pct_total | 97.0 | 98.0 | 100.4 | 100.7 |
| rss_kb | 105693.9 | 105764.0 | 106312.0 | 106312.0 |
| cpu0_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 1662
| metric | value |
|---|---:|
| mean interval ms | 69.72 |
| median interval ms | 72.15 |
| p95 interval ms | 122.53 |
| p99 interval ms | 138.28 |
| implied fps | 14.34 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

