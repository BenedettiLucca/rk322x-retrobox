## psx3d-crash-r3

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 88.4 | 88.3 | 89.2 | 89.2 |
| cpu_pct_total | 99.0 | 100.1 | 102.9 | 103.1 |
| rss_kb | 105720.6 | 105694.0 | 106240.0 | 106240.0 |
| cpu0_freq_khz | 1118466 | 1200000 | 1200000 | 1200000 |
| cpu1_freq_khz | 1121096 | 1200000 | 1200000 | 1200000 |
| cpu2_freq_khz | 1121096 | 1200000 | 1200000 | 1200000 |
| cpu3_freq_khz | 1123726 | 1200000 | 1200000 | 1200000 |

Page flips (from strace DRM ioctls): 2217
| metric | value |
|---|---:|
| mean interval ms | 52.71 |
| median interval ms | 40.87 |
| p95 interval ms | 105.39 |
| p99 interval ms | 119.15 |
| implied fps | 18.97 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

