#!/usr/bin/env python3
"""Summarize a run-scene.sh output directory as Markdown.

Usage: analyze.py OUTDIR [OUTDIR ...]
Reads samples.csv, strace.log (optional) and meta.json.
"""
import csv
import datetime as dt
import json
import os
import re
import statistics
import sys


def pct(values, p):
    if not values:
        return None
    s = sorted(values)
    k = (len(s) - 1) * p / 100.0
    lo, hi = int(k), min(int(k) + 1, len(s) - 1)
    return s[lo] + (s[hi] - s[lo]) * (k - lo)


def numeric(row, key):
    try:
        return float(row.get(key) or 0)
    except (TypeError, ValueError):
        return 0.0


def read_samples(path):
    rows = []
    with open(path) as f:
        for r in csv.DictReader(f):
            rows.append(r)
    return rows


def read_pageflips(path):
    """Return timestamps (seconds since midnight) of DRM page-flip ioctls."""
    times = []
    pat = re.compile(r'^\s*(?:\d+\s+)?(\d\d):(\d\d):(\d\d\.\d+)\s+ioctl\(.*?(PAGE_FLIP|PAGE_FLIP_TARGET)')
    with open(path) as f:
        for line in f:
            m = pat.match(line)
            if m:
                h, mi, s = int(m.group(1)), int(m.group(2)), float(m.group(3))
                times.append(h * 3600 + mi * 60 + s)
    return times


def summarize(outdir):
    meta_path = os.path.join(outdir, 'meta.json')
    meta = {}
    if os.path.isfile(meta_path):
        with open(meta_path) as f:
            meta = json.load(f)

    warmup = float(os.environ.get('BENCH_WARMUP', '0'))

    lines = ['## %s' % meta.get('label', os.path.basename(outdir)), '']
    if warmup:
        lines.append('- Analysis window: first %.0fs discarded (BENCH_WARMUP)' % warmup)
    lines.append('- Status: %s (exit %s)' % (meta.get('status', '?'), meta.get('exit_code', '?')))
    lines.append('- Requested frames: %s' % meta.get('frames_requested', '?'))
    lines.append('- Elapsed: %ss' % meta.get('elapsed_s', '?'))
    lines.append('- Frames/s wall (includes startup): %s' % meta.get(
        'frames_per_s_wall', meta.get('effective_fps_vsync', '?')))
    lines.append('')

    samples = read_samples(os.path.join(outdir, 'samples.csv')) if os.path.isfile(os.path.join(outdir, 'samples.csv')) else []
    if warmup and samples:
        t0 = numeric(samples[0], 'time_s')
        samples = [r for r in samples if numeric(r, 'time_s') - t0 >= warmup]
    if samples:
        def col(key):
            return [numeric(r, key) for r in samples]
        temp = [t for t in col('temp_c') if t and t < 200000]
        temp_c = [t / 1000.0 for t in temp] if temp and max(temp) > 1000 else temp
        cpu = col('cpu_pct')
        rss = [v for v in col('rss_kb') if v]
        lines.append('| Metric | mean | median | p95 | max |')
        lines.append('|---|---:|---:|---:|---:|')
        for name, vals in [('temp_c', temp_c), ('cpu_pct_total', cpu), ('rss_kb', rss)]:
            if vals:
                lines.append('| %s | %.1f | %.1f | %.1f | %.1f |' % (
                    name, statistics.mean(vals), statistics.median(vals), pct(vals, 95) or 0, max(vals)))
        for i in range(4):
            vals = [v for v in col('freq%d_khz' % i) if v]
            if vals:
                lines.append('| cpu%d_freq_khz | %.0f | %.0f | %.0f | %.0f |' % (
                    i, statistics.mean(vals), statistics.median(vals), pct(vals, 95) or 0, max(vals)))
        lines.append('')
    else:
        lines.append('_No samples.csv._')
        lines.append('')

    trace = os.path.join(outdir, 'strace.log')
    if os.path.isfile(trace):
        times = read_pageflips(trace)
        if warmup and times:
            t0 = times[0]
            times = [t for t in times if t - t0 >= warmup]
        deltas = [(b - a) * 1000 for a, b in zip(times, times[1:]) if 0 < b - a < 5]
        if deltas:
            lines.append('Page flips (from strace DRM ioctls): %d' % len(times))
            lines.append('| metric | value |')
            lines.append('|---|---:|')
            lines.append('| mean interval ms | %.2f |' % statistics.mean(deltas))
            lines.append('| median interval ms | %.2f |' % statistics.median(deltas))
            lines.append('| p95 interval ms | %.2f |' % pct(deltas, 95))
            lines.append('| p99 interval ms | %.2f |' % pct(deltas, 99))
            lines.append('| implied fps | %.2f |' % (1000.0 / statistics.mean(deltas)))
            lines.append('')
        else:
            lines.append('_strace.log present but no page-flip ioctls parsed._')
            lines.append('')

    log = os.path.join(outdir, 'ra.log')
    if os.path.isfile(log):
        with open(log, errors='replace') as f:
            tail = f.read().splitlines()[-15:]
        lines.append('RA log tail:')
        lines.append('```')
        lines.extend(tail)
        lines.append('```')
    return '\n'.join(lines)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit('Usage: analyze.py OUTDIR [OUTDIR ...]')
    for d in sys.argv[1:]:
        print(summarize(d))
        print()
