-- WX: weather data shaping and ink glyphs for XT Weather on the XTOS Licorice host.
-- The host runs one self-contained script per app, so this module travels inside index.lua
-- (inlined by tools/gamekit/bundle.py) and is reachable as require('wx').

local X = {}

-- Interpret a WMO weather code (as delivered by Open-Meteo) -> glyph kind + human label.
function X.kind(code)
  local n = tonumber(code) or 0
  local kind, label
  if n == 0 then kind, label = 'sun', 'Clear sky'
  elseif n == 1 then kind, label = 'sun', 'Mostly clear'
  elseif n == 2 then kind, label = 'partly', 'Partly cloudy'
  elseif n == 3 then kind, label = 'cloud', 'Overcast'
  elseif n == 45 or n == 48 then kind, label = 'fog', 'Fog'
  elseif n >= 51 and n <= 57 then kind, label = 'drizzle', 'Drizzle'
  elseif n >= 61 and n <= 67 then kind, label = 'rain', n >= 65 and 'Heavy rain' or 'Rain'
  elseif n >= 71 and n <= 77 then kind, label = 'snow', 'Snow'
  elseif n >= 80 and n <= 82 then kind, label = 'shower', 'Rain showers'
  elseif n == 85 or n == 86 then kind, label = 'snow', 'Snow showers'
  elseif n >= 95 then kind, label = 'storm', 'Thunderstorm'
  else kind, label = 'cloud', 'Cloudy' end
  return kind, label
end

-- Open-Meteo forecast endpoint (free, no key needed).
function X.forecast_url(lat, lon, unit)
  local q = {
    latitude = tostring(lat), longitude = tostring(lon),
    current = 'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m',
    hourly = 'temperature_2m,precipitation_probability,weather_code',
    daily = 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
    forecast_days = '4', timezone = 'auto', wind_speed_unit = 'kmh'
  }
  if unit == 'F' then q.temperature_unit = 'fahrenheit' end
  local parts = {}
  for k, v in pairs(q) do parts[#parts + 1] = k .. '=' .. v end
  return 'https://api.open-meteo.com/v1/forecast?' .. table.concat(parts, '&')
end

local function rnd(x) return x and math.floor(x + 0.5) or nil end

-- Open-Meteo JSON -> the "key=value" cache text stored between launches.
function X.cache_text(d, place, unit, now)
  local c = d.current or {}
  local out = {
    'place=' .. tostring(place), 'unit=' .. tostring(unit), 'updated=' .. tostring(now),
    'now_t=' .. (rnd(c.temperature_2m) or ''), 'now_feel=' .. (rnd(c.apparent_temperature) or ''),
    'now_code=' .. tostring(c.weather_code or 0), 'now_hum=' .. (rnd(c.relative_humidity_2m) or ''),
    'now_wind=' .. (rnd(c.wind_speed_10m) or '')
  }
  local h = d.hourly or {}
  local times = h.time or {}
  local first = 1
  local cur = tostring(c.time or ''):sub(1, 13)
  for i, t in ipairs(times) do
    if tostring(t):sub(1, 13) >= cur then
      first = i
      break
    end
  end
  for k = 0, 11 do
    local i = first + k
    if times[i] then
      out[#out + 1] = 'h' .. k .. '=' .. tostring(times[i]):sub(12, 16) .. ';' .. (rnd((h.temperature_2m or {})[i]) or '') .. ';' ..
        tostring((h.precipitation_probability or {})[i] or '') .. ';' .. tostring((h.weather_code or {})[i] or 0)
    end
  end
  local dd = d.daily or {}
  for i, t in ipairs(dd.time or {}) do
    out[#out + 1] = 'd' .. (i - 1) .. '=' .. tostring(t) .. ';' .. tostring((dd.weather_code or {})[i] or 0) .. ';' ..
      (rnd((dd.temperature_2m_min or {})[i]) or '') .. ';' .. (rnd((dd.temperature_2m_max or {})[i]) or '') .. ';' ..
      tostring((dd.precipitation_probability_max or {})[i] or '')
  end
  return table.concat(out, '\n')
end

function X.parse_cache(text)
  if not text then return nil end
  local t = {}
  for k, v in text:gmatch('([%w_]+)=([^\n]*)') do t[k] = v end
  if not t.place then return nil end
  local f = {
    place = t.place, unit = t.unit or 'C', updated = tonumber(t.updated),
    now_t = tonumber(t.now_t), now_feel = tonumber(t.now_feel), now_code = tonumber(t.now_code) or 0,
    now_hum = tonumber(t.now_hum), now_wind = tonumber(t.now_wind), hours = {}, days = {}
  }
  for k = 0, 11 do
    local v = t['h' .. k]
    if v then
      local tm, temp, rain, code = v:match('^([^;]*);([^;]*);([^;]*);([^;]*)$')
      if tm then f.hours[#f.hours + 1] = { time = tm, temp = tonumber(temp), rain = tonumber(rain), code = tonumber(code) or 0 } end
    end
  end
  for k = 0, 6 do
    local v = t['d' .. k]
    if v then
      local date, code, lo, hi, rain = v:match('^([^;]*);([^;]*);([^;]*);([^;]*);([^;]*)$')
      if date then f.days[#f.days + 1] = { date = date, code = tonumber(code) or 0, lo = tonumber(lo), hi = tonumber(hi), rain = tonumber(rain) } end
    end
  end
  return f
end

-- Weekday for a "YYYY-MM-DD" date (Zeller's congruence, 0 = Saturday).
local DAYS = { 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' }
function X.weekday(date)
  local y, m, d = date:match('^(%d+)-(%d+)-(%d+)')
  y, m, d = tonumber(y), tonumber(m), tonumber(d)
  if not y then return '' end
  if m < 3 then y, m = y - 1, m + 12 end
  local k = (d + (13 * (m + 1)) // 5 + y + y // 4 - y // 100 + y // 400) % 7
  return DAYS[(k + 6) % 7 + 1]
end

------------------------------------------------------------------ drawing

local function circle(gg, x, y, rad) pcall(function() gg:circle(x, y, rad) end) end

-- Weather glyph in a square of size s, top-left corner (x, y).
function X.icon(gg, kind, x, y, s)
  local function cloud(cx, cy, w)
    local h = w * 0.55
    local pts = {}
    local shape = { 0.1, 1, 0.9, 1, 1, 0.75, 0.88, 0.45, 0.68, 0.42, 0.6, 0.1, 0.35, 0.05, 0.22, 0.35, 0.05, 0.5, 0, 0.8, 0.1, 1 }
    for i = 1, #shape, 2 do
      pts[#pts + 1] = math.floor(cx + shape[i] * w)
      pts[#pts + 1] = math.floor(cy + shape[i + 1] * h)
    end
    gg:polyline(pts)
  end
  if kind == 'sun' then
    local cx, cy, rad = x + s // 2, y + s // 2, s // 5
    circle(gg, cx, cy, rad)
    circle(gg, cx, cy, rad - 1)
    for k = 0, 7 do
      local a = k * math.pi / 4
      gg:line(math.floor(cx + math.cos(a) * rad * 1.5), math.floor(cy + math.sin(a) * rad * 1.5),
        math.floor(cx + math.cos(a) * rad * 2.2), math.floor(cy + math.sin(a) * rad * 2.2))
    end
  elseif kind == 'partly' then
    local cx, cy, rad = x + s * 0.35, y + s * 0.3, s // 7
    circle(gg, math.floor(cx), math.floor(cy), rad)
    for k = 0, 4 do
      local a = math.pi * (0.75 + k * 0.25)
      gg:line(math.floor(cx + math.cos(a) * rad * 1.5), math.floor(cy + math.sin(a) * rad * 1.5),
        math.floor(cx + math.cos(a) * rad * 2.2), math.floor(cy + math.sin(a) * rad * 2.2))
    end
    cloud(x + s * 0.2, y + s * 0.35, s * 0.75)
  elseif kind == 'fog' then
    for k = 0, 3 do gg:line(x + s // 8 + (k % 2) * 6, y + s // 3 + k * s // 8, x + s - s // 8 - (k % 2) * 6, y + s // 3 + k * s // 8) end
  else
    cloud(x + s * 0.08, y + s * 0.12, s * 0.84)
    local by = math.floor(y + s * 0.72)
    if kind == 'rain' or kind == 'drizzle' or kind == 'shower' then
      for k = 0, 2 do local lx = math.floor(x + s * (0.3 + k * 0.2)); gg:line(lx, by, lx - 5, by + s // 5) end
    elseif kind == 'snow' then
      for k = 0, 2 do
        local lx = math.floor(x + s * (0.3 + k * 0.2))
        gg:line(lx - 4, by + 6, lx + 4, by + 6)
        gg:line(lx, by + 2, lx, by + 10)
      end
    elseif kind == 'storm' then
      local lx = math.floor(x + s * 0.5)
      gg:polyline({ lx + 4, by - 2, lx - 6, by + s // 8, lx + 4, by + s // 8, lx - 6, by + s // 4 })
    end
  end
end

-- Seven-segment rendering of a (possibly signed) integer string: digit height h, thickness t.
local SEG = { ['0'] = 'abcdef', ['1'] = 'bc', ['2'] = 'abged', ['3'] = 'abgcd', ['4'] = 'fgbc', ['5'] = 'afgcd',
             ['6'] = 'afgedc', ['7'] = 'abc', ['8'] = 'abcdefg', ['9'] = 'abcdfg', ['-'] = 'g' }
function X.big_number(gg, s, x, y, h)
  local w, t = h // 2, math.max(4, h // 10)
  local half = h // 2
  for ch in tostring(s):gmatch('.') do
    local seg = SEG[ch]
    if seg then
      for sg in seg:gmatch('.') do
        if sg == 'a' then gg:rect(x, y, w, t, { fill = true })
        elseif sg == 'b' then gg:rect(x + w - t, y, t, half, { fill = true })
        elseif sg == 'c' then gg:rect(x + w - t, y + half, t, h - half, { fill = true })
        elseif sg == 'd' then gg:rect(x, y + h - t, w, t, { fill = true })
        elseif sg == 'e' then gg:rect(x, y + half, t, h - half, { fill = true })
        elseif sg == 'f' then gg:rect(x, y, t, half, { fill = true })
        elseif sg == 'g' then gg:rect(x, y + half - t // 2, w, t, { fill = true }) end
      end
      x = x + w + t * 2
    end
  end
  return x
end
function X.big_width(s, h)
  local w, t = h // 2, math.max(4, h // 10)
  local n = 0
  for ch in tostring(s):gmatch('.') do if SEG[ch] then n = n + 1 end end
  return n * (w + t * 2)
end

return X
