## psx3d-crash-drcoff-r1

- Analysis window: first 30s discarded (BENCH_WARMUP)
- Status: ok (exit 124)
- Requested frames: 999999
- Elapsed: 157s
- Frames/s wall (includes startup): 6369.42

| Metric | mean | median | p95 | max |
|---|---:|---:|---:|---:|
| temp_c | 89.2 | 89.2 | 90.0 | 90.0 |
| cpu_pct_total | 117.0 | 118.9 | 120.8 | 121.0 |
| rss_kb | 94654.0 | 94564.0 | 95024.0 | 95024.0 |
| cpu0_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu1_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |
| cpu2_freq_khz | 1005570 | 1008000 | 1008000 | 1008000 |
| cpu3_freq_khz | 1008000 | 1008000 | 1008000 | 1008000 |

Page flips (from strace DRM ioctls): 1267
| metric | value |
|---|---:|
| mean interval ms | 91.31 |
| median interval ms | 83.79 |
| p95 interval ms | 148.61 |
| p99 interval ms | 159.54 |
| implied fps | 10.95 |

RA log tail:
```

Session terminated, killing shell... ...killed.
```

