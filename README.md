# 🌤️ XT Weather v1.3.0 for Xteink X4 Pro (XTOS Licorice)

[![Platform](https://img.shields.io/badge/Platform-Xteink%20X4%20Pro-black?style=flat-square)](https://xteink.com)
[![Firmware](https://img.shields.io/badge/OS-XTOS%20Licorice-orange?style=flat-square)](https://github.com/Valblasp/XT-Weather)
[![Display](https://img.shields.io/badge/Display-Portrait%20%26%20Landscape-lightgrey?style=flat-square)](https://github.com/Valblasp/XT-Weather)
[![Version](https://img.shields.io/badge/Version-v1.3.0-green?style=flat-square)](https://github.com/Valblasp/XT-Weather/releases)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

A clean, 100% open-source native weather forecast application for the **Xteink X4 Pro** e-reader running the official **XTOS Licorice** firmware. 

Inspired by the minimalist Material You design of **Google Weather**, specifically formatted and optimized for 480×800 (and 800×480) monochrome e-paper displays.

---

## 🚀 What's New in v1.3.0

- 🔄 **OTA Auto-Updates Direct from GitHub**: The app checks for new updates on launch. An **`[Update]`** button automatically appears on screen to download the new `.xtapp` directly over Wi-Fi without needing a PC.
- ⚡ **Auto-Refresh on Launch**: Connects to Wi-Fi immediately upon launch to pull real-time weather from Open-Meteo without having to manually tap "Refresh". Wi-Fi turns off right after syncing to conserve battery.
- 🏠 **Clean Hardware Exit**: Pressing the central **Home pad** or the **Back key** cleanly closes the app back to the system launcher/reader menu.
- 📐 **Native Landscape & Portrait Modes**: Available in both **Portrait (Vertical - 480×800)** and **Landscape (Horizontal - 800×480)**. Both editions can be installed and used simultaneously on your device!
- 📖 **Full Open Source Release**: The complete project source code (Lua source, UI framework, packaging scripts) is now fully available in this repository.

---

## ✨ Features

- **Google Weather Aesthetic**: Large high-contrast temperature readout, crisp monochrome WMO weather icons, feels-like temperature, wind speed (km/h), and humidity %.
- **Hourly Forecast**: Step-by-step projection with temperature and rain probability (shows up to 8 continuous hourly slots in Landscape mode).
- **4-Day Outlook**: Daily low / high temperature ranges and precipitation probabilities.
- **Standalone Wi-Fi**: Fetches live weather data and geocoding directly via the **Open-Meteo API** (free, no account or API keys required). Disables Wi-Fi immediately after syncing to preserve battery life.
- **Global Place Search**: Search any city, town, or location worldwide using the built-in firmware keyboard.
- **Unit Toggle**: One-tap toggle between Celsius (`°C`) and Fahrenheit (`°F`).
- **Instant Launch**: Caches your last forecast locally for instantaneous loading upon opening.

---

## 📥 Installation

### 1. Download
Grab the pre-compiled binary packages from this repository or the [Releases](https://github.com/Valblasp/XT-Weather/releases) section:

| Edition | File | Best For | Resolution |
|---|---|---|---|
| **Portrait (Vertical)** | [`xtweather.xtapp`](xtweather.xtapp) | Handheld reading mode | 480 × 800 |
| **Landscape (Horizontal)** | [`xtweatherland.xtapp`](xtweatherland.xtapp) | Desk stand / nightstand dock | 800 × 480 |

*(You can install both versions at the same time on your device!)*

### 2. Transfer to Device
1. Connect your **Xteink X4 Pro** to your computer via USB.
2. Copy `xtweather.xtapp` (and/or `xtweatherland.xtapp`) directly to the **root** of your SD card / internal storage.
3. Eject the device safely.

### 3. Install on XTOS Licorice
1. **Unlock Developer Mode (First time only)**:
   - On your Xteink, go to **Settings** ➔ **About**.
   - Tap **"Model" 10 times consecutively**. You'll see a notification that the **Ink App** drawer is now unlocked.
2. **Install**:
   - Open **All Files** on your device.
   - Tap the `.xtapp` file and select **Install**.
3. **Launch**:
   - Open the **Ink App** drawer from the side menu and tap **XT Weather**!

---

## 🧭 How to Use

- **Search Place**: Tap the **Place** button at the bottom, type your city using the on-screen keyboard, and pick your location from the results.
- **Refresh**: Tap **Refresh** to reconnect to Wi-Fi and fetch the latest forecast.
- **Switch Units**: Tap **°C** or **°F** at the bottom to switch temperature units instantly.
- **Exit**: Press the central **Home pad** or the **Back key** to return to the reader menu.
- **Update**: When an update is detected, tap the **Update** button that appears in the toolbar.

---

## 🛠️ Project Structure & Building from Source

This repository contains the complete, unabridged source code:

```text
├── apps/
│   └── weather/
│       ├── manifest.json       # App metadata & network permissions
│       ├── icon.png            # 96x96 1bpp e-ink icon
│       └── src/
│           ├── main.lua        # UI, adaptive layouts, OTA updater, input handling
│           └── wx.lua          # WMO code mapping, weather icons, caching, big digits
├── tools/
│   ├── gamekit/
│   │   ├── bundle.py           # Inlines gamekit & modules into index.lua
│   │   └── gamekit.lua         # UI toolkit for XTOS Licorice
│   ├── vendor/
│   │   ├── xtapp.py            # Cryptographic container signing & packaging
│   │   └── mksd.py             # Storage sector utilities
│   └── lualint55.py            # Lua 5.5 syntax verification
├── build_both.py               # One-click build script for both orientations
├── xtpack.py                   # .xtapp container packer
└── version.json                # OTA version indicator for auto-updates
```

### Compiling with Python

Requires Python 3.9+ with `cryptography` and `pillow`:

```bash
pip install cryptography pillow
python build_both.py
```

This validates the Lua code with `lualint55`, bundles modules, and produces signed `xtweather.xtapp` and `xtweatherland.xtapp` packages in the project root.

---

## 📄 License & Attribution

- Source code licensed under the [MIT License](LICENSE).
- Weather data courtesy of [Open-Meteo.com](https://open-meteo.com) (CC BY 4.0).
- Compatible with the [touch-licorice-apps](https://github.com/omer-faruq-xteink/touch-licorice-apps) community framework.
