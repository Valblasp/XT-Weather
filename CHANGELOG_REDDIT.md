# [RELEASE] XT Weather v1.4.2 for Xteink X4 Pro: Menu + safer updates

Hey everyone! 👋

Quick follow-up to the Liquid Glass redesign:

- **🧭 Menu button**: the settings entry is now **Menu** (previously *Options*). Inside: Place, °C/°F, Check updates, version and Close.
- **📲 Download-only updates**: the app saves the `.xtapp` to **App Files** and shows a prompt telling you where to install it — it never tries to install on its own.
- **🔄 Auto update check**: after every weather refresh, the app also looks for a new version.

---

# [RELEASE] XT Weather v1.4.0 for Xteink X4 Pro: Liquid Glass redesign in our own code!

Hey everyone! 👋

Following the v1.3.x line, the app got a full **visual makeover**: the forecast glance was rebuilt around the **Liquid Glass** design — frosted glass surfaces, large rounded numerals, refined typography and a floating glass toolbar.

The previous code (heavily inspired by a big-G weather experience) has been **replaced wholesale by a fresh implementation** of the forecast logic, cache, icons and drawing routines, so the app is now 100% our own code.

---

### 🌤️ What's New in v1.4.0

1. **🍏 Liquid Glass Redesign**:
   - Frosted glass surfaces, large rounded numerals, refined typography hierarchy.
   - Floating glass action bar at the bottom.

2. **🧑‍💻 Own Codebase**:
   - All forecast/engine/drawing code substituted with a brand-new implementation.

---

### 🌤️ What's New in v1.3.0

1. **📖 100% Open Source Repository**:
   - The full Lua source code, UI framework, packaging scripts, and vector assets are now available on GitHub for anyone to study, audit, or build from source!

2. **🔄 OTA Auto-Updates Direct from GitHub**:
   - The app now checks for updates on startup. Whenever a new build is published to GitHub, an **`[Update]`** button appears directly on the device to download the new `.xtapp` over Wi-Fi!

3. **⚡ Auto-Refresh on Launch**:
   - The app now automatically connects to Wi-Fi and fetches the freshest weather forecast from Open-Meteo the moment you open it. Wi-Fi turns off immediately after syncing to preserve battery life.

4. **🏠 Hardware Home Pad & Back Exit**:
   - Pressing the central **Home pad** or the **Back key** now cleanly closes the app back to the system launcher/reader menu.

5. **📐 Dedicated Portrait & Landscape Modes**:
   - **`xtweather.xtapp` (480×800)**: Vertical handheld reading layout.
   - **`xtweatherland.xtapp` (800×480)**: Dual-pane horizontal layout with 8 continuous hourly forecast columns and side-by-side 4-day outlook (ideal for desk stands, docks, and nightstands).
   - *Both can be installed simultaneously on your device!*

---

### 📥 Installation

1. Connect your X4 Pro via USB.
2. Copy `xtweather.xtapp` (and/or `xtweatherland.xtapp`) directly to the **root** of your SD card / internal storage.
3. Open **All Files** on the device, tap the `.xtapp` file, and select **Install**.
4. Launch the app from the **Ink App** side drawer!

---

### 📦 GitHub & Downloads

- **GitHub Repository (Source Code & Releases)**: [https://github.com/Valblasp/XT-Weather](https://github.com/Valblasp/XT-Weather)
- **Data Source**: Open-Meteo.com (Free, CC BY 4.0)
- **License**: MIT

Feel free to check out the code, submit pull requests, or let me know what features you'd like to see next!
