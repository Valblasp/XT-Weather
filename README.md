# 🌤️ XT Weather

[![Platform](https://img.shields.io/badge/Platform-Xteink%20X4%20Pro-black?style=flat-square)](https://xteink.com)
[![Firmware](https://img.shields.io/badge/OS-XTOS%20Licorice-orange?style=flat-square)](https://github.com/Valblasp/XT-Weather)
[![Screen](https://img.shields.io/badge/Display-4.3%22%20E--Ink%20(480x800)-lightgrey?style=flat-square)](https://github.com/Valblasp/XT-Weather)
[![Version](https://img.shields.io/badge/Version-v1.4.2-green?style=flat-square)](https://github.com/Valblasp/XT-Weather/releases)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

A clean, native weather forecast application for the **Xteink X4 Pro** e-reader running the official **XTOS Licorice** firmware.

Redesigned in **v1.4.1** around the **Liquid Glass** design: frosted glass surfaces, large rounded numerals, refined typography scale and a floating glass toolbar — everything re-implemented from scratch in our own code. **v1.4.2** adds a cleaner **Menu** and a safer update flow.

---

## ✨ Features

- **Liquid Glass Design**: frosted glass panels, hairline separators, large rounded temperature numerals, SF-style type scale and a floating glass action bar.
- **Hourly Forecast**: Step-by-step projection for the next 12 hours with temperature and chance of rain.
- **4-Day Outlook**: Daily low / high temperature ranges and precipitation probabilities.
- **Standalone Wi-Fi**: Fetches live weather data and geocoding directly via the **Open-Meteo API** (free, no account or API keys required). Disables Wi-Fi immediately after syncing to preserve battery life.
- **Global Place Search**: Search any city, town, or location worldwide using the built-in firmware keyboard.
- **Unit Toggle**: One-tap toggle between Celsius (`°C`) and Fahrenheit (`°F`).
- **Instant Launch**: Caches your last forecast locally for instantaneous loading upon opening.
- **OTA Auto-Updates**: Detects and downloads new versions directly over Wi-Fi — no PC or USB cable required.

---

## 🚀 What's New in v1.4.2

### 🧭 Menu Button

- The settings entry is now a **Menu** button on the floating glass bar.
- Inside: **Place**, **unit switch** (`°C` / `°F`), **Check updates**, app version and **Close**.

### 📲 Download-Only Updates

- The app **never installs automatically**: it downloads the `.xtapp` file to **App Files** and shows an on-screen prompt explaining where to install it.
- When an update is detected you choose **Download** or **Later**.

### 🔄 Automatic Update Check

- After every weather refresh, the app also checks for a new version — no need to open the menu.

### 🍏 Liquid Glass Redesign & New Icon

- Complete visual overhaul with the **Liquid Glass** design language: frosted glass surfaces, large rounded numerals, refined typography and a floating glass toolbar.
- **New app icon** reflecting the new era of the app.
- Forecast engine, cache, icons and drawing routines rebuilt as a fresh implementation.

---

## 📋 Changelog

| Version | Highlights |
|---|---|
| **v1.4.2** | Menu button; download-only updates with prompt; auto update check after refresh |
| v1.4.1 | Liquid Glass redesign + new icon; fresh implementation |
| v1.3.5 | OTA download to App Files with guided install prompt |
| v1.3.4 | Compact header (city + updated time on one line), 5-day forecast fixed |
| v1.3.2 | Menu (Place, °C/°F, version, Check Updates) |
| v1.3.1 | City name displayed bolder |
| v1.3.0 | OTA update system, auto-refresh on launch, hardware Home/Back exit, portrait & landscape modes |

---

## 📥 Installation

### 1. Download
Grab the latest release from the [Releases](https://github.com/Valblasp/XT-Weather/releases/latest) section:

- 👉 **[xtweather.xtapp](https://github.com/Valblasp/XT-Weather/releases/latest)** — Portrait edition *(~36 KB)*
- 👉 **[xtweatherland.xtapp](https://github.com/Valblasp/XT-Weather/releases/latest)** — Landscape edition *(~36 KB)*

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

- **Refresh**: Tap **Refresh** to reconnect to Wi-Fi and fetch the latest forecast. It also checks for a new app version.
- **Menu**: Tap **Menu** to open the settings sheet:
  - **Place** — Search for any city or town worldwide.
  - **Switch to °C / °F** — Toggle temperature units.
  - **Check updates** — Look for a new version manually.
  - **Close** — Dismiss the menu.
- **Exit**: Press the central **Home pad** or the **Back key** to return to the reader menu.
- **Update**: When a new version is detected, choose **Download**. The file is saved to **App Files** (never installed automatically), and a prompt tells you to open **All Files**, tap the `.xtapp` and choose **Install**.

---

## 🛠️ Tech Stack & Architecture

- **Runtime**: Native Lua mini-app host built into XTOS Licorice (API 2.0+).
- **Resolution**: Native 480 × 800 px and 800 × 480 px monochrome rasterization with e-ink refresh optimizations.
- **Weather API**: Powered by [Open-Meteo.com](https://open-meteo.com) (licensed under CC BY 4.0).
- **OTA Updates**: Version check via `version.json` hosted on GitHub. File downloads to device App Files storage.

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).  
Weather data courtesy of [Open-Meteo.com](https://open-meteo.com) (CC BY 4.0).
