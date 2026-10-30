# 🌤️ XT Weather v1.3.0 — Release Notes & Changelog

## 🚀 What's New in v1.3.0

### 🔄 OTA Auto-Updates from GitHub
- **Direct Device Updates**: The app now checks `version.json` in this repository on startup. When you publish a new build to GitHub, an **`[Update]`** button automatically appears in the app to download the latest `.xtapp` directly on the device!

### ⚡ Auto-Refresh on Launch
- **Real-Time Weather on Open**: The app connects to Wi-Fi immediately upon launch to pull the freshest forecast from Open-Meteo. No need to manually tap "Refresh". Wi-Fi turns off immediately after the sync.

### 🏠 Hardware Home & Back Exit
- **Central Home Pad Exit**: Pressing the central Home pad / Menu button now cleanly exits the app back to the system launcher.
- **Back Key Exit**: Pressing Back on the main screen also exits the application cleanly.

### 📐 Dedicated Portrait (480×800) & Landscape (800×480) Modes
- **`xtweather.xtapp`**: Vertical handheld reading layout.
- **`xtweatherland.xtapp`**: Dual-pane horizontal layout with 8 continuous hourly columns and side-by-side 4-day forecast (perfect for desk stands & docks).
- Both editions can be installed simultaneously on your device!

### 📖 100% Open Source Repository
- The entire project source code (Lua source, UI framework, packaging scripts) is now fully available in the GitHub repository.

---

## 📦 Assets & Downloads
- **`xtweather.xtapp`**: Portrait / Vertical version (480×800)
- **`xtweatherland.xtapp`**: Landscape / Horizontal version (800×480)
- **`version.json`**: OTA update metadata file
