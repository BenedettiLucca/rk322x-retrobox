#!/bin/sh
# Read-only system inventory for RK322x benchmarking.
# Run on the box (root or lucca). Emits JSON on stdout.
set -eu

python3 - <<'PY'
import glob, hashlib, json, os, re, subprocess, datetime

def sh(cmd, timeout=20):
    try:
        p = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return (p.stdout + p.stderr).strip()
    except Exception as e:
        return "ERROR: %s" % e

def read(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except Exception:
        return ""

def sha256(path):
    try:
        h = hashlib.sha256()
        with open(path, 'rb') as f:
            for chunk in iter(lambda: f.read(1 << 20), b''):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return ""

def kv_paths(pattern):
    out = {}
    for p in glob.glob(pattern):
        out[os.path.basename(p)] = read(p)
    return out

d = {}
d['meta'] = {
    'timestamp': datetime.datetime.now().astimezone().isoformat(),
    'hostname': sh('hostname'),
    'uname': sh('uname -a'),
    'user': os.environ.get('USER', ''),
}

d['soc'] = {
    'compatible': read('/proc/device-tree/compatible').replace('\x00', ' '),
    'cmdline': read('/proc/cmdline'),
    'cpuinfo_model': (re.search(r'^model name\s*:\s*(.*)$', read('/proc/cpuinfo'), re.M) or [None, ''])[1],
    'lscpu': sh('lscpu'),
}

pol = '/sys/devices/system/cpu/cpufreq/policy0'
d['cpufreq'] = kv_paths(pol + '/scaling_*') if os.path.isdir(pol) else {}
d['cpufreq'].update({
    'cpuinfo_min_freq': read(pol + '/cpuinfo_min_freq'),
    'cpuinfo_max_freq': read(pol + '/cpuinfo_max_freq'),
})

d['thermal'] = []
for zone in sorted(glob.glob('/sys/class/thermal/thermal_zone*')):
    d['thermal'].append({
        'name': os.path.basename(zone),
        'type': read(zone + '/type'),
        'temp': read(zone + '/temp'),
        'mode': read(zone + '/mode'),
        'cur_state': read(zone + '/cur_state'),
    })

d['devfreq'] = {}
for dev in glob.glob('/sys/class/devfreq/*'):
    d['devfreq'][os.path.basename(dev)] = {
        'cur_freq': read(dev + '/cur_freq'),
        'min_freq': read(dev + '/min_freq'),
        'max_freq': read(dev + '/max_freq'),
        'governor': read(dev + '/governor'),
    }

d['drm'] = {
    'cards': [os.path.basename(p) for p in sorted(glob.glob('/dev/dri/card*'))],
    'connectors': {},
    'modetest_c': sh('modetest -c', timeout=30)[:12000],
}
for conn in sorted(glob.glob('/sys/class/drm/card*-HDMI-A-*')):
    d['drm']['connectors'][os.path.basename(conn)] = {
        'status': read(conn + '/status'),
        'modes': read(conn + '/modes').splitlines(),
        'enabled': read(conn + '/enabled'),
    }

d['memory'] = {
    'free': sh('free -h'),
    'swap': sh('swapon --show'),
    'zram': sh('zramctl') if sh('command -v zramctl') else 'zramctl absent',
    'pressure': read('/proc/pressure/memory') or 'PSI absent',
    'vmstat': sh('vmstat 1 2'),
}

pkgs = sh("dpkg-query -W -f='${binary:Package} ${Version}\\n' 2>/dev/null | grep -E 'mesa|libdrm|libgbm|libegl|libgles|lima' | sort")
d['packages'] = pkgs.splitlines()

d['graphics_driver'] = sh("dmesg 2>/dev/null | grep -iE 'lima|rockchip-drm|rga|mali400' | tail -30")
d['rga'] = {
    'devices': [os.path.basename(p) for p in sorted(glob.glob('/dev/video*'))],
    'sysfs': glob.glob('/sys/bus/platform/devices/*rga*'),
}

ra = '/usr/local/bin/retroarch-kms'
d['retroarch'] = {
    'path': ra,
    'exists': os.path.isfile(ra),
    'sha256': sha256(ra),
    'version': sh(ra + ' --version'),
    'features': sh(ra + ' --features | grep -iE "kms|egl|opengles|drm"'),
}

d['cores'] = []
for p in sorted(glob.glob('/usr/local/lib/libretro/*.so') + glob.glob('/usr/lib/arm-linux-gnueabihf/libretro/*.so')):
    d['cores'].append({
        'path': p,
        'size': os.path.getsize(p),
        'sha256': sha256(p),
        'file': sh('file -b ' + repr(p)),
    })

cfg = '/home/lucca/.config/retroarch/retroarch-kms.cfg'
d['config'] = {}
for line in read(cfg).splitlines():
    m = re.match(r'\s*([a-zA-Z0-9_]+)\s*=\s*(.*)', line)
    if m and re.match(r'^(video|audio|rewind|run_ahead|audio_latency|input_menu)', m.group(1)):
        d['config'][m.group(1)] = m.group(2).strip('"')

opt = '/home/lucca/.config/retroarch/config/PCSX-ReARMed/PCSX-ReARMed.opt'
d['pcsx_options'] = {}
for line in read(opt).splitlines():
    m = re.match(r'\s*([a-zA-Z0-9_]+)\s*=\s*(.*)', line)
    if m:
        d['pcsx_options'][m.group(1)] = m.group(2).strip('"')

d['tools'] = {t: bool(sh('command -v ' + t)) for t in
              ['modetest', 'strace', 'perf', 'eglinfo', 'es2_info', 'v4l2-ctl', 'gcc', 'fbgrab', 'python3']}

print(json.dumps(d, indent=2, ensure_ascii=False))
PY
