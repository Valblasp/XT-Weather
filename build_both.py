"""Build both Portrait (xtweather.xtapp) and Landscape (xtweatherland.xtapp)
for Xteink X4 Pro running XTOS Licorice.

Also generates lockscreen.lua by calling apps/weather/bundle.py which
bundles src/wx.lua + src/lock/lock.lua into a standalone lockscreen entry.

Usage:
    python build_both.py
"""
import os
import sys
import json
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
WEATHER_DIR = os.path.join(HERE, 'apps', 'weather')
OUT_DIR = HERE  # Output directly in repo root

VERSION = '1.4.2'

COMMON = {
    "author": "Valblasp",
    "entry": "index.lua",
    "api": "2.0",
    "permissions": ["net"],
    "lockscreen": {
        "enabled": True,
        "entry": "lockscreen.lua",
        "interval_sec": 3600
    }
}

DESCRIPTION_BASE = (
    "Liquid Glass weather forecast for Xteink X4 Pro (Open-Meteo). "
    "Enhanced fork of touch-licorice-apps by Omer Faruk Inel."
)

port_manifest = {
    "app_id": "xtweather",
    "display_name": "XT Weather",
    "version": VERSION,
    "description": DESCRIPTION_BASE,
    **COMMON
}

land_manifest = {
    "app_id": "xtweatherland",
    "display_name": "XT Weather Land",
    "version": VERSION,
    "description": DESCRIPTION_BASE + " Landscape edition.",
    "display": {"orientation": "landscape"},
    **COMMON
}


def write_manifest(d):
    with open(os.path.join(WEATHER_DIR, 'manifest.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(d, f, indent=2)


def run(cmd):
    subprocess.run(cmd, check=True)


# Step 1: generate index.lua + lockscreen.lua via apps/weather/bundle.py
run([sys.executable, os.path.join(WEATHER_DIR, 'bundle.py')])

# --- Portrait build ---
write_manifest(port_manifest)

index_path = os.path.join(WEATHER_DIR, 'index.lua')
with open(index_path, 'r', encoding='utf-8') as f:
    idx_content = f.read()

port_out = os.path.join(OUT_DIR, 'xtweather.xtapp')
run([sys.executable, os.path.join(HERE, 'xtpack.py'), WEATHER_DIR, '-o', port_out])
print('[OK] Portrait build:', port_out)

# --- Landscape build ---
write_manifest(land_manifest)

idx_land = idx_content.replace('kit.W, kit.H = 480, 800', 'kit.W, kit.H = 800, 480')
with open(index_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(idx_land)

land_out = os.path.join(OUT_DIR, 'xtweatherland.xtapp')
run([sys.executable, os.path.join(HERE, 'xtpack.py'), WEATHER_DIR, '-o', land_out])
print('[OK] Landscape build:', land_out)

# --- Restore portrait defaults ---
write_manifest(port_manifest)
with open(index_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(idx_content)
print('[OK] Restored portrait defaults.')
print(f'[OK] Build complete: XT Weather v{VERSION}')
