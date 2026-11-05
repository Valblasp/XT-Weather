-- XT Weather: liquid-glass style forecast glance for the Xteink X4 Pro on XTOS Licorice.
-- Originally forked from touch-licorice-apps by Omer Faruk Inel; enhanced with Liquid Glass UI,
-- OTA updates, options menu, and expanded forecasts.
--
-- Layout: portrait (480x800) and landscape (800x480) are handled by the same state machine.
-- Data: Open-Meteo (free, no key) -> key=value cache file -> on-screen glance.

local X = require('wx')
local STALE_S = 30 * 60
local UA = 'XT Weather/1.4.6 (https://github.com/Valblasp/XT-Weather)'

local APP_VERSION = '1.4.6'
local UPDATE_URL = 'https://raw.githubusercontent.com/Valblasp/XT-Weather/xt-weather/version.json'
local update_info = nil

local cfg = { name = nil, lat = nil, lon = nil, unit = 'C' }
local fc = nil                  -- parsed forecast cache (X.parse_cache)
local screen = 'main'           -- main | places
local places = {}
local status, busy_label, ERR = nil, nil, nil

local function layout(gg)
  local w, h = kit.W or 480, kit.H or 800
  if gg and gg.size then
    local ok, sw, sh = pcall(function() return gg:size() end)
    if ok and type(sw) == 'number' and type(sh) == 'number' and sw > 0 and sh > 0 then
      w, h = sw, sh
    end
  end
  local is_land = (w > h)
  local bar_h = is_land and 50 or 66
  local bar_y = h - bar_h - 12
  return { w = w, h = h, is_land = is_land, bar_y = bar_y, bar_h = bar_h }
end

local L = layout()

local function now_sec()
  local ok, t = pcall(function() return ctx.clock:now() end)
  if ok and type(t) == 'table' and tonumber(t.epoch_sec) then return math.floor(tonumber(t.epoch_sec)) end
  return 0
end

local function hhmm(epoch)
  if not epoch then return '' end
  local ok, t = pcall(function() return ctx.clock:now() end)
  if not ok or type(t) ~= 'table' or not tonumber(t.hour) then return '' end
  local wall = tonumber(t.hour) * 3600 + (tonumber(t.minute) or 0) * 60 - (now_sec() - tonumber(epoch))
  wall = wall % 86400
  return string.format('%02d:%02d', wall // 3600, (wall % 3600) // 60)
end

------------------------------------------------------------------ storage

local function save_cfg()
  kit.write('settings.txt', 'name=' .. (cfg.name or '') .. '\nlat=' .. (cfg.lat or '') .. '\nlon=' .. (cfg.lon or '') ..
    '\nunit=' .. cfg.unit)
end

local function load_cfg()
  local t = kit.kv(kit.read('settings.txt'))
  cfg.name = (t.name and t.name ~= '') and t.name or nil
  cfg.lat, cfg.lon = tonumber(t.lat), tonumber(t.lon)
  cfg.unit = t.unit == 'F' and 'F' or 'C'
  fc = X.parse_cache(kit.read('forecast.txt'))
end

------------------------------------------------------------------ network

local function keep_wifi() pcall(function() ctx.net:keep_wifi(5 * 60 * 1000) end) end

local pending = nil
local function get(url, label, on_done)
  if pending then return end
  keep_wifi()
  busy_label, pending = label, { since = kit.now_ms() }
  local job = pending
  local ok, err = pcall(function()
    ctx.net:request({ url = url, method = 'GET', headers = { ['User-Agent'] = UA }, timeout_ms = 30000 }, function(c, resp)
      if pending ~= job then return end
      pending, busy_label = nil, nil
      local okh, e = pcall(function()
        if type(resp) ~= 'table' or type(resp.body) ~= 'string' then on_done(nil, 'no answer'); return end
        local code = tonumber(resp.status) or tonumber(resp.code)
        if code and code >= 400 then on_done(nil, 'HTTP ' .. code); return end
        local okj, data = pcall(function() return ctx.json:decode(resp.body) end)
        on_done(okj and type(data) == 'table' and data or nil, nil, resp.body)
      end)
      if not okh then status = 'Error: ' .. kit.short(tostring(e), 40) end
      kit.refresh()
    end)
  end)
  if not ok then pending, busy_label, status = nil, nil, 'Could not ask: ' .. kit.short(tostring(err), 30) end
end

local download_update  -- defined below; used by the update prompt

local function check_update(announce)
  get(UPDATE_URL, 'Checking update...', function(d, err, raw)
    if not d or type(d) ~= 'table' then
      if announce then status = 'Update check failed: ' .. tostring(err or 'no answer') end
      return
    end
    local remote_ver = tostring(d.version or '')
    if remote_ver ~= '' and remote_ver ~= APP_VERSION then
      local is_land = L and L.is_land
      local file_url = is_land and d.download_url_land or d.download_url
      local file_name = is_land and (d.filename_land or 'xtweatherland.xtapp') or (d.filename or 'xtweather.xtapp')
      local known = update_info ~= nil and update_info.version == remote_ver
      update_info = {
        version = remote_ver,
        url = file_url,
        filename = file_name,
        notes = tostring(d.notes or '')
      }
      status = 'New update v' .. remote_ver .. '! Tap Update'
      if not known then
        kit.show({
          title = 'Update v' .. remote_ver .. ' available',
          lines = { 'Download it now? The file is saved to App Files.', 'It is not installed automatically.' },
          cancel = function() kit.close() end,
          rows = {
            { { 'Download', function() kit.close(); download_update() end, true } },
            { { 'Later', function() kit.close() end, true } }
          }
        })
      end
    else
      update_info = nil
      if announce then status = 'Up to date (v' .. APP_VERSION .. ')' end
    end
  end)
end

local function refresh_forecast()
  if not cfg.lat then status = 'Choose a place first.'; return end
  get(X.forecast_url(cfg.lat, cfg.lon, cfg.unit), 'Getting the forecast...', function(d, err)
    if not d then status = 'Forecast failed: ' .. tostring(err); return end
    local text = X.cache_text(d, cfg.name, cfg.unit, now_sec())
    kit.write('forecast.txt', text)
    fc = X.parse_cache(text)
    status = nil
    check_update()   -- after a fresh forecast, also look for a new app version
  end)
end

download_update = function()
  if not update_info or not update_info.url then return end
  local target_url = update_info.url
  local fname = update_info.filename
  busy_label = 'Downloading update...'
  status = 'Downloading v' .. update_info.version .. '...'
  kit.refresh()

  get(target_url, 'Downloading update...', function(d, err, raw_body)
    if not raw_body or #raw_body < 1000 then
      status = 'Download failed: ' .. tostring(err or 'empty')
      return
    end
    local okw = pcall(function()
      if ctx.files and ctx.files.write then
        ctx.files:write(fname, raw_body)
      else
        kit.write(fname, raw_body)
      end
    end)
    if okw then
      busy_label = nil
      status = nil
      kit.show({
        title = 'Update downloaded',
        lines = { fname .. ' saved to App Files.', 'Open All Files, tap it, then Install.' },
        cancel = function() kit.close() end,
        rows = { { { 'OK', function() kit.close() end, true } } }
      })
    else
      status = 'Could not save file.'
    end
  end)
end

local function find_place(q)
  get('https://geocoding-api.open-meteo.com/v1/search?count=8&language=en&format=json&name=' ..
      q:gsub('[^A-Za-z0-9%-%._~]', function(c) return string.format('%%%02X', c:byte()) end),
      'Looking for ' .. kit.short(q, 20) .. '...', function(d, err)
    if not d then status = 'Search failed: ' .. tostring(err); return end
    places = {}
    for _k, p in ipairs(d.results or {}) do
      local where = {}
      if p.admin1 then where[#where + 1] = tostring(p.admin1) end
      if p.country then where[#where + 1] = tostring(p.country) end
      places[#places + 1] = { name = tostring(p.name), lat = tonumber(p.latitude), lon = tonumber(p.longitude),
                              where = table.concat(where, ', ') }
    end
    screen, status = 'places', (#places == 0 and 'No place by that name.' or nil)
  end)
end

local function ask_place()
  ctx.input:text({ title = 'Place (city or town)', text = '' }, function(c, s)
    if s and s:match('%S') then find_place(s) end
    kit.refresh()
  end)
end

local function open_menu()
  local unit_label = cfg.unit == 'C' and 'Switch to °F' or 'Switch to °C'
  kit.show({
    title = 'Menu',
    lines = { 'Place: ' .. (cfg.name or 'not set'), 'Version ' .. APP_VERSION },
    cancel = function() kit.close() end,
    rows = {
      { { 'Place', function() kit.close(); ask_place() end, true } },
      { { unit_label, function()
          kit.close()
          cfg.unit = cfg.unit == 'C' and 'F' or 'C'
          save_cfg()
          refresh_forecast()
        end, true } },
      { { 'Check updates', function() kit.close(); check_update(true) end, true } },
      { { 'Close', function() kit.close() end, true } }
    }
  })
end

------------------------------------------------------------------ drawing

local function deg(v) return v and (tostring(v) .. '°') or '-' end

local function draw_glass_bar(gg)
  gg:rect(12, L.bar_y, L.w - 24, L.bar_h, { line_width = 2 })
  gg:rect(14, L.bar_y + 2, L.w - 28, L.bar_h - 4, { line_width = 1 })
end

local function draw_button(gg, x, y, w, h, label)
  gg:rect(x, y, w, h, { line_width = 2 })
  local f = kit.font('medium')
  local s = tostring(label)
  while #s > 1 and kit.width(f, s) > w - 10 do s = kit.drop_last(s) end
  gg:text(x + math.floor((w - kit.width(f, s)) / 2), y + math.floor((h - kit.line_h('medium')) / 2), s, { font = f })
end

local function draw_main_portrait(gg)
  local W = L.w
  -- header panel: city (left) + updated time (right)
  gg:rect(8, 4, W - 16, 46, { line_width = 2 })
  gg:rect(10, 6, W - 20, 42, { line_width = 1 })
  gg:text(16, 14, kit.short(fc.place, 22), { font = kit.font('large') })
  local upd_str = 'updated ' .. hhmm(fc.updated) .. (now_sec() - (fc.updated or 0) > STALE_S and '  (old)' or '')
  gg:text(W - kit.width(kit.font('small'), upd_str) - 16, 22, upd_str, { font = kit.font('small') })
  gg:line(0, 56, W, 56, { line_width = 2 })

  local kind, label = X.kind(fc.now_code)
  gg:text(16, 66, label, { font = kit.font('large') })

  -- big temperature + icon
  local temp = fc.now_t and tostring(fc.now_t) or '-'
  local bx = X.big_number(gg, temp, 20, 96, 120)
  gg:text(bx + 4, 96, '°' .. fc.unit, { font = kit.font('large') })
  X.icon(gg, kind, W - 132, 72, 120)

  -- feels-like glass panel
  gg:rect(12, 228, W - 24, 86, { line_width = 2 })
  gg:rect(14, 230, W - 28, 82, { line_width = 1 })
  gg:text(20, 240, 'Feels like ' .. deg(fc.now_feel), { font = kit.font('medium') })
  gg:text(20, 270, 'Humidity ' .. (fc.now_hum or '-') .. '%', { font = kit.font('small') })
  gg:text(20, 292, 'Wind ' .. (fc.now_wind or '-') .. ' km/h', { font = kit.font('small') })

  gg:text(16, 326, 'Hourly', { font = kit.font('medium') })
  local col = W // 6
  for k = 1, 6 do
    local h = fc.hours[(k - 1) * 2 + 1]
    if h then
      local cx = (k - 1) * col
      gg:text(cx + 8, 348, h.time, { font = kit.font('small') })
      X.icon(gg, X.kind(h.code), cx + 12, 372, 44)
      gg:text(cx + 10, 420, deg(h.temp), { font = kit.font('medium') })
      gg:text(cx + 10, 446, (h.rain or 0) .. '%', { font = kit.font('small') })
    end
  end
  gg:line(0, 468, W, 468, { line_width = 2 })

  gg:text(16, 480, '4-Day Outlook', { font = kit.font('medium') })
  for k, d in ipairs(fc.days) do
    if k > 4 then break end
    local y = 500 + (k - 1) * 52
    gg:text(16, y + 14, k == 1 and 'Today' or X.weekday(d.date), { font = kit.font('medium') })
    X.icon(gg, X.kind(d.code), 100, y + 4, 44)
    gg:text(160, y + 14, deg(d.lo) .. ' / ' .. deg(d.hi), { font = kit.font('medium') })
    gg:text(290, y + 16, 'rain ' .. (d.rain or 0) .. '%', { font = kit.font('small') })
    if k < 4 then gg:line(16, y + 52, W - 16, y + 52, { line_width = 1 }) end
  end
end

local function draw_main_landscape(gg)
  local W = L.w
  -- header panel
  gg:rect(8, 4, W - 16, 44, { line_width = 2 })
  gg:rect(10, 6, W - 20, 40, { line_width = 1 })
  gg:text(16, 14, kit.short(fc.place, 26), { font = kit.font('large') })
  local upd_str = 'updated ' .. hhmm(fc.updated) .. (now_sec() - (fc.updated or 0) > STALE_S and '  (old)' or '')
  gg:text(W - kit.width(kit.font('small'), upd_str) - 16, 20, upd_str, { font = kit.font('small') })
  gg:line(0, 52, W, 52, { line_width = 2 })

  local kind, label = X.kind(fc.now_code)
  gg:text(20, 62, label, { font = kit.font('large') })
  local temp = fc.now_t and tostring(fc.now_t) or '-'
  local bx = X.big_number(gg, temp, 20, 84, 72)
  gg:text(bx + 4, 84, '°' .. fc.unit, { font = kit.font('large') })
  X.icon(gg, kind, W - 130, 58, 90)

  -- feels glass panel
  gg:rect(16, 166, 340, 68, { line_width = 2 })
  gg:rect(18, 168, 336, 64, { line_width = 1 })
  gg:text(24, 176, 'Feels like ' .. deg(fc.now_feel), { font = kit.font('medium') })
  gg:text(24, 200, 'Humidity ' .. (fc.now_hum or '-') .. '%   Wind ' .. (fc.now_wind or '-') .. ' km/h', { font = kit.font('small') })

  gg:line(366, 52, 366, 236, { line_width = 2 })
  gg:line(0, 236, W, 236, { line_width = 2 })

  for k, d in ipairs(fc.days) do
    if k <= 4 then
      local y = 56 + (k - 1) * 44
      gg:text(386, y + 8, k == 1 and 'Today' or X.weekday(d.date), { font = kit.font('medium') })
      X.icon(gg, X.kind(d.code), 480, y, 36)
      gg:text(530, y + 8, deg(d.lo) .. ' / ' .. deg(d.hi), { font = kit.font('medium') })
      gg:text(690, y + 10, 'rain ' .. (d.rain or 0) .. '%', { font = kit.font('small') })
      if k < 4 then gg:line(386, y + 44, W - 16, y + 44, { line_width = 1 }) end
    end
  end

  local slots = 8
  local col = W // slots
  gg:text(16, 244, 'Hourly', { font = kit.font('medium') })
  for k = 1, slots do
    local h = fc.hours[k]
    if h then
      local cx = (k - 1) * col
      gg:text(cx + 18, 262, h.time, { font = kit.font('small') })
      X.icon(gg, X.kind(h.code), cx + 22, 282, 36)
      gg:text(cx + 20, 322, deg(h.temp), { font = kit.font('medium') })
      gg:text(cx + 20, 346, (h.rain or 0) .. '%', { font = kit.font('small') })
    end
  end
  gg:line(0, 360, W, 360, { line_width = 2 })
end

local function draw_main(gg)
  if not fc then
    gg:text(16, 16, 'XT Weather', { font = kit.font('large') })
    gg:text(16, L.is_land and 80 or 140, cfg.lat and 'Tap Refresh for the forecast.' or 'Tap Place to choose where.', { font = kit.font('medium') })
    return
  end
  if L.is_land then
    draw_main_landscape(gg)
  else
    draw_main_portrait(gg)
  end
end

local function draw_places(gg)
  local W = L.w
  gg:text(16, 16, 'Choose the place', { font = kit.font('large') })
  if not L.is_land then
    gg:line(0, 84, W, 84)
    for k, p in ipairs(places) do
      local y = 96 + (k - 1) * 76
      gg:text(20, y + 6, kit.short(p.name, 30), { font = kit.font('medium') })
      gg:text(20, y + 38, kit.short(p.where, 46), { font = kit.font('small') })
      gg:line(16, y + 70, W - 16, y + 70)
    end
  else
    gg:line(0, 46, W, 46)
    gg:line(395, 46, 395, L.bar_y - 8)
    for k, p in ipairs(places) do
      if k <= 8 then
        local col_idx = (k <= 4) and 0 or 1
        local row_idx = (k <= 4) and (k - 1) or (k - 5)
        local bx = (col_idx == 0) and 20 or 415
        local lx1 = (col_idx == 0) and 16 or 410
        local lx2 = (col_idx == 0) and 380 or (W - 16)
        local y = 52 + row_idx * 76
        gg:text(bx, y + 6, kit.short(p.name, 26), { font = kit.font('medium') })
        gg:text(bx, y + 38, kit.short(p.where, 38), { font = kit.font('small') })
        gg:line(lx1, y + 70, lx2, y + 70)
      end
    end
  end
end

local function buttons()
  if screen == 'places' then return { 'Back', 'Search again' } end
  if update_info then return { 'Update', 'Refresh', 'Menu' } end
  return { 'Refresh', 'Menu' }
end

local function button_rect(k, n)
  local bw = math.floor((L.w - 24 - (n - 1) * 8) / n)
  return 12 + (k - 1) * (bw + 8), L.bar_y, bw, L.bar_h
end

function on_draw(c, gg)
  if not gg then return end
  local ok, e = pcall(function()
    L = layout(gg)
    gg:clear(0)
    if kit.modal() then kit.draw_modal(gg); return end
    if screen == 'places' then draw_places(gg) else draw_main(gg) end
    local line = busy_label or status or ERR
    if line then
      local ly = L.bar_y - (L.is_land and 24 or 30)
      gg:text(12, ly, kit.short(tostring(line), L.is_land and 80 or 48), { font = kit.font('small') })
    end
    local bs = buttons()
    draw_glass_bar(gg)
    for k, b in ipairs(bs) do
      local x, y, bw, bh = button_rect(k, #bs)
      draw_button(gg, x, y, bw, bh, b)
    end
  end)
  if not ok then pcall(function() gg:text(8, L.h - 60, kit.short('draw ERR ' .. tostring(e), 46)) end) end
end

------------------------------------------------------------------ input

local function tap(x, y)
  if kit.tap_modal(x, y) then return end
  local bs = buttons()
  for k, b in ipairs(bs) do
    local bx, by, bw, bh = button_rect(k, #bs)
    if x >= bx and x < bx + bw and y >= by and y < by + bh then
      status = nil
      if b == 'Update' then download_update()
      elseif b == 'Refresh' then refresh_forecast()
      elseif b == 'Menu' then open_menu()
      elseif b == 'Place' or b == 'Search again' then ask_place()
      elseif b == 'Back' then screen = 'main'
      else
        cfg.unit = cfg.unit == 'C' and 'F' or 'C'
        save_cfg()
        refresh_forecast()
      end
      return
    end
  end
  if screen == 'places' then
    local p = nil
    if not L.is_land and y >= 96 then
      p = places[(y - 96) // 76 + 1]
    elseif L.is_land and y >= 52 and y < L.bar_y - 8 then
      local row = (y - 52) // 76
      if row >= 0 and row < 4 then
        local idx = (x < 395) and (row + 1) or (row + 5)
        p = places[idx]
      end
    end
    if p then
      cfg.name, cfg.lat, cfg.lon = p.name, p.lat, p.lon
      save_cfg()
      screen = 'main'
      refresh_forecast()
    end
  end
end

local function try_quit()
  pcall(function()
    if ctx.quit then ctx:quit()
    elseif ctx.system and ctx.system.quit then ctx.system:quit()
    elseif ctx.system and ctx.system.exit then ctx.system:exit()
    end
  end)
end

function on_input(c, ev)
  ERR = nil
  local ok, e = pcall(function()
    if type(ev) ~= 'table' then return end
    if ev.type == 'pointer' and ev.phase == 'up' then tap(ev.x or 0, ev.y or 0)
    elseif ev.type == 'key' and kit.key_accepted(ev) then
      if ev.key == 'home' or ev.key == 'menu' then
        try_quit()
        return false
      elseif kit.modal() then
        if ev.key == 'back' and kit.modal().cancel then kit.modal().cancel() end
      elseif ev.key == 'back' and screen == 'places' then screen = 'main'
      elseif ev.key == 'back' then
        try_quit()
        return false
      end
    end
  end)
  if not ok then ERR = tostring(e) end
  kit.refresh()
  return true
end

function on_load(c)
  local ok, e = pcall(load_cfg)
  if not ok then ERR = tostring(e) end
  if cfg.lat then refresh_forecast() else check_update() end
end

function on_leave() pcall(function() ctx.net:keep_wifi(1) end) end

if rawget(_G, '__TEST') then
  __TEST.api = { X = X, fc = function() return fc end, cfg = cfg, screen = function() return screen end,
                 places = function() return places end, status = function() return status end }
end
