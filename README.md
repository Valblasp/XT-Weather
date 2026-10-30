# 🌤️ XT Weather

[![Platform](https://img.shields.io/badge/Platform-Xteink%20X4%20Pro-black?style=flat-square)](https://xteink.com)
[![Firmware](https://img.shields.io/badge/OS-XTOS%20Licorice-orange?style=flat-square)](https://github.com/Valblasp/XT-Weather)
[![Screen](https://img.shields.io/badge/Display-4.3%22%20E--Ink%20(480x800)-lightgrey?style=flat-square)](https://github.com/Valblasp/XT-Weather)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

A clean, native weather forecast application for the **Xteink X4 Pro** e-reader running the official **XTOS Licorice** firmware. 

Inspired by the minimalist Material You design of **Google Weather**, specifically formatted and optimized for 480×800 e-paper displays.

---

## ✨ Features

- **Google Weather Aesthetic**: Large high-contrast temperature readout, crisp monochrome WMO weather icons, feels-like temperature, wind speed, and humidity.
- **Hourly Forecast**: Step-by-step projection for the next 12 hours with temperature and chance of rain.
- **4-Day Outlook**: Daily low / high temperature ranges and precipitation probabilities.
- **Standalone Wi-Fi**: Fetches live weather data and geocoding directly via the **Open-Meteo API** (free, no account or API keys required). Disables Wi-Fi immediately after syncing to preserve battery life.
- **Global Place Search**: Search any city, town, or location worldwide using the built-in firmware keyboard.
- **Unit Toggle**: One-tap toggle between Celsius (`°C`) and Fahrenheit (`°F`).
- **Instant Launch**: Caches your last forecast locally for instantaneous loading upon opening.

---

## 📥 Installation

### 1. Download
Grab the latest pre-compiled binary package:
- 👉 **[Download xtweather.xtapp](https://github.com/Valblasp/XT-Weather/releases/latest)** *(~28 KB)*

### 2. Transfer to Device
1. Connect your **Xteink X4 Pro** to your computer via USB.
2. Copy `xtweather.xtapp` directly to the **root** of your SD card / internal storage.
3. Eject the device safely.

### 3. Install on XTOS Licorice
1. **Unlock Developer Mode (First time only)**:
   - On your Xteink, go to **Settings** ➔ **About**.
   - Tap **"Model" 10 times consecutively**. You'll see a notification that the **Ink App** drawer is now unlocked.
2. **Install**:
   - Open **All Files** on your device.
   - Tap `xtweather.xtapp` and select **Install**.
3. **Launch**:
   - Open the **Ink App** drawer from the side menu and tap **XT Weather**!

---

## 🧭 How to Use

- **Search Place**: Tap the **Place** button at the bottom, type your city using the on-screen keyboard, and pick your location from the results.
- **Refresh**: Tap **Refresh** to reconnect to Wi-Fi and fetch the latest forecast.
- **Switch Units**: Tap **°C** or **°F** at the bottom to switch temperature units instantly.

---

## 🛠️ Tech Stack & Architecture

- **Runtime**: Native Lua mini-app host built into XTOS Licorice (API 2.0+).
- **Resolution**: Native 480 × 800 px monochrome rasterization with e-ink refresh optimizations.
- **Weather API**: Powered by [Open-Meteo.com](https://open-meteo.com) (licensed under CC BY 4.0).

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
