# 🌤️ XT Weather

[![Platform](https://img.shields.io/badge/Platform-Xteink%20X4%20Pro-black?style=flat-square)](https://xteink.com)
[![Firmware](https://img.shields.io/badge/OS-XTOS%20Licorice-orange?style=flat-square)](https://github.com/Valblasp/XT-Weather)
[![Screen](https://img.shields.io/badge/Display-4.3%22%20E--Ink%20(480x800)-lightgrey?style=flat-square)](https://github.com/Valblasp/XT-Weather)
[![Version](https://img.shields.io/badge/Version-v1.3.2-green?style=flat-square)](https://github.com/Valblasp/XT-Weather/releases)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

A clean, native weather forecast application for the **Xteink X4 Pro** e-reader running the official **XTOS Licorice** firmware.

Inspired by the minimalist Material You design of **Google Weather**, specifically formatted and optimized for 480×800 e-paper displays.

---

## ✨ Features

- **Google Weather Aesthetic**: Large high-contrast temperature readout, crisp monochrome WMO weather icons, feels-like temperature, wind speed, and humidity.
- **Hourly Forecast**: Step-by-step projection for the next 12 hours with temperature and chance of rain.
- **5-Day Outlook**: Daily low / high temperature ranges and precipitation probabilities (portrait mode).
- **Standalone Wi-Fi**: Fetches live weather data and geocoding directly via the **Open-Meteo API** (free, no account or API keys required). Disables Wi-Fi immediately after syncing to preserve battery life.
- **Global Place Search**: Search any city, town, or location worldwide using the built-in firmware keyboard.
- **Unit Toggle**: One-tap toggle between Celsius (`°C`) and Fahrenheit (`°F`) from the Options menu.
- **Instant Launch**: Caches your last forecast locally for instantaneous loading upon opening.
- **OTA Auto-Updates**: Detects and installs new versions directly over Wi-Fi, no PC required.

---

## 🚀 What's New in v1.3.2

### ⚙️ Options Menu
Place, unit toggle, app version, and update check are now grouped in a single **Options** button. The main screen is cleaner with just **Refresh** and **Options**.

### 📅 5-Day Forecast (Portrait)
Portrait mode now shows **5 days** of daily forecast instead of 4, making better use of the available screen space.

---

## 📋 Changelog

| Version | Highlights |
|---|---|
| **v1.3.2** | Options menu, 5-day forecast in portrait |
| v1.3.1.1 | Housekeeping: .gitignore, removed pycache |
| v1.3.1 | City name displayed bolder |
| v1.3.0 | OTA auto-updates, auto-refresh on launch, hardware Home/Back exit, portrait & landscape modes |

---

## 📥 Installation

### 1. Download
Grab the latest release from the [Releases](https://github.com/Valblasp/XT-Weather/releases/latest) section:

- 👉 **[xtweather.xtapp](https://github.com/Valblasp/XT-Weather/releases/latest)** — Portrait edition *(~35 KB)*
- 👉 **[xtweatherland.xtapp](https://github.com/Valblasp/XT-Weather/releases/latest)** — Landscape edition *(~35 KB)*

### 2. Transfer to Device
1. Connect your **Xteink X4 Pro** to your computer via USB.
2. Copy `xtweather.xtapp` (and/or `xtweatherland.xtapp`) directly to the **root** of your SD card / internal storage.
3. Eject the device safely.

### 3. Install on XTOS Licorice
1. **Unlock Developer Mode (first time only)**:
   - On your Xteink, go to **Settings** ➔ **About**.
   - Tap **"Model" 10 times consecutively**. A notification will confirm that the **Ink App** drawer is now unlocked.
2. **Install**:
   - Open **All Files** on your device.
   - Tap the `.xtapp` file and select **Install**.
3. **Launch**:
   - Open the **Ink App** drawer from the side menu and tap **XT Weather**!

---

## 🧭 How to Use

- **Refresh**: Tap **Refresh** to reconnect to Wi-Fi and fetch the latest forecast.
- **Options**: Tap **Options** to open the settings menu:
  - **Place** — Search for any city or town worldwide.
  - **Switch to °C / °F** — Toggle temperature units instantly.
  - **Check Updates** — Manually check for a new version on GitHub.
  - **Close** — Dismiss the menu.
- **Exit**: Press the central **Home pad** or the **Back key** to return to the reader menu.
- **Update**: When an update is detected, tap the **Update** button that appears in the toolbar to install it wirelessly.

---

## 🛠️ Tech Stack & Architecture

- **Runtime**: Native Lua mini-app host built into XTOS Licorice (API 2.0+).
- **Resolution**: Native 480 × 800 px and 800 × 480 px monochrome rasterization with e-ink refresh optimizations.
- **Weather API**: Powered by [Open-Meteo.com](https://open-meteo.com) (licensed under CC BY 4.0).
- **OTA Updates**: Version check via `version.json` hosted on GitHub.

---

## 🏗️ Building from Source

This repository contains the complete source code. Requires **Python 3.9+** with `cryptography` and `pillow`:

```bash
pip install cryptography pillow
python build_both.py
```

This validates the Lua source with `lualint55`, bundles modules, and produces signed `xtweather.xtapp` and `xtweatherland.xtapp` packages ready for installation.

**Project structure:**

```text
├── apps/
│   └── weather/
│       ├── manifest.json       # App metadata & network permissions
│       ├── icon.png            # 96×96 1bpp e-ink icon
│       └── src/
│           ├── main.lua        # UI, layouts, OTA updater, Options menu, input handling
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
└── version.json                # OTA version manifest for auto-updates
```

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).  
Weather data courtesy of [Open-Meteo.com](https://open-meteo.com) (CC BY 4.0).
