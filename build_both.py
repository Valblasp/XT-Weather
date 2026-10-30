"""Build both Portrait (xtweather.xtapp) and Landscape (xtweatherland.xtapp)
for Xteink X4 Pro running XTOS Licorice.

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

# Remove unused lockscreen.lua if present
ls_file = os.path.join(WEATHER_DIR, 'lockscreen.lua')
if os.path.exists(ls_file):
    os.remove(ls_file)

# 1. Build Portrait (480x800)
port_manifest = {
    "app_id": "xtweather",
    "display_name": "XT Weather",
    "version": "1.3.0",
    "author": "Valblasp",
    "description": "Detailed weather forecast inspired by Google Weather for Xteink X4 Pro (Open-Meteo).",
    "entry": "index.lua",
    "api": "2.0",
    "permissions": ["net"]
}

with open(os.path.join(WEATHER_DIR, 'manifest.json'), 'w', encoding='utf-8', newline='\n') as f:
    json.dump(port_manifest, f, indent=2)

subprocess.run([sys.executable, os.path.join(HERE, 'tools', 'gamekit', 'bundle.py'), WEATHER_DIR], check=True)

port_out = os.path.join(OUT_DIR, 'xtweather.xtapp')
subprocess.run([sys.executable, os.path.join(HERE, 'xtpack.py'), WEATHER_DIR, '-o', port_out], check=True)
print('[OK] Portrait build created:', port_out)

# 2. Build Landscape (800x480)
land_manifest = {
    "app_id": "xtweatherland",
    "display_name": "XT Weather Land",
    "version": "1.3.0",
    "author": "Valblasp",
    "description": "Detailed weather forecast (Landscape) for Xteink X4 Pro (Open-Meteo).",
    "entry": "index.lua",
    "api": "2.0",
    "display": {
        "orientation": "landscape"
    },
    "permissions": ["net"]
}

with open(os.path.join(WEATHER_DIR, 'manifest.json'), 'w', encoding='utf-8', newline='\n') as f:
    json.dump(land_manifest, f, indent=2)

index_path = os.path.join(WEATHER_DIR, 'index.lua')
with open(index_path, 'r', encoding='utf-8') as f:
    idx_content = f.read()

idx_land = idx_content.replace('kit.W, kit.H = 480, 800', 'kit.W, kit.H = 800, 480')
with open(index_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(idx_land)

land_out = os.path.join(OUT_DIR, 'xtweatherland.xtapp')
subprocess.run([sys.executable, os.path.join(HERE, 'xtpack.py'), WEATHER_DIR, '-o', land_out], check=True)
print('[OK] Landscape build created:', land_out)

# 3. Restore Portrait defaults
with open(os.path.join(WEATHER_DIR, 'manifest.json'), 'w', encoding='utf-8', newline='\n') as f:
    json.dump(port_manifest, f, indent=2)
with open(index_path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(idx_content)
print('[OK] Restored default portrait files.')
