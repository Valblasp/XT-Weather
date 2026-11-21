-- XT Weather lock screen entry.
-- Shown as the device wallpaper / lock screen via XTOS Licorice lockscreen API.
-- Reads forecast.txt written by the main app. Refreshes if data is over 1 hour old.
-- Does NOT depend on gamekit - works as a standalone XTOS lockscreen script.
-- Based on the lockscreen architecture from touch-licorice-apps by Omer Faruk Inel.

local W, H = 480, 800
local STALE_S = 60 * 60   -- 1 hour: refresh threshold
local UA = 'XT Weather/1.5.6.4 (https://github.com/Valblasp/XT-Weather)'
local asked_at = nil

-- Storage helpers (ctx.storage, no kit available here)
local function read(name)
  local ok, s = pcall(function() return ctx.storage:read(name) end)
  return (ok and type(s) == 'string') and s or nil
end

-- Font helper
local function font(name)
  if ctx.fonts then return ctx.fonts[name] end
  return nil
end

-- Current time in epoch seconds
local function now_sec()
  local ok, t = pcall(function() return ctx.clock:now() end)
  if ok and type(t) == 'table' and tonumber(t.epoch_sec) then
    return math.floor(tonumber(t.epoch_sec))
  end
  return 0
end

local function deg(v) return v and (tostring(v) .. '°') or '-' end

-- Burn-in protection: tiny pseudo-random shift that changes every few minutes,
-- so static content never sits on the exact same pixels for hours.
local function burnin_offset()
  local t = now_sec()
  local ox = (math.floor(t / 300) % 5) - 2   -- -2..2, changes every 5 min
  local oy = (math.floor(t / 480) % 5) - 2   -- -2..2, changes every 8 min
  return ox, oy
end

-- Attempt a background weather refresh if data is stale
local function try_refresh(fc)
  local t = {}
  for k, v in (read('settings.txt') or ''):gmatch('([%w_]+)=([^\n]*)') do t[k] = v end
  local lat, lon = tonumber(t.lat), tonumber(t.lon)
  if not lat then return end
  -- Rate-limit: don't ask again within 15 minutes
  if asked_at and now_sec() - asked_at < 15 * 60 then return end
  asked_at = now_sec()
  pcall(function()
    ctx.net:request({
      url = X.forecast_url(lat, lon, t.unit == 'F' and 'F' or 'C'),
      method = 'GET',
      headers = { ['User-Agent'] = UA },
      timeout_ms = 30000
    }, function(c, resp)
      pcall(function()
        if type(resp) ~= 'table' or type(resp.body) ~= 'string' then return end
        local d = ctx.json:decode(resp.body)
        if type(d) ~= 'table' then return end
        ctx.storage:write('forecast.txt',
          X.cache_text(d, t.name or (fc and fc.place or ''), t.unit == 'F' and 'F' or 'C', now_sec()))
        pcall(function()
          if ctx.invalidate then ctx:invalidate() end
        end)
      end)
    end)
  end)
end

function on_draw(c, gg)
  local g = gg or c
  if not g then return end
  local ox, oy = burnin_offset()
  local ok, err = pcall(function()
    if g.size then
      local ok_s, sw, sh = pcall(function() return g:size() end)
      if ok_s and sw and sh and sw > 0 and sh > 0 then
        W, H = sw, sh
      end
    end

    g:clear(0)

    local fc = X.parse_cache(read('forecast.txt'))
    if not fc then
      g:text(24 + ox, H / 2 + oy, 'XT Weather: open the app once to set a city.', { font = font('medium') })
      return
    end

    -- Refresh if stale (> 1 hour)
    local age = now_sec() - (fc.updated or 0)
    if age > STALE_S then try_refresh(fc) end

    local is_land = W > H
    local place_str = tostring(fc.place)
    local temp = fc.now_t and tostring(fc.now_t) or '-'
    local kind, text = X.kind(fc.now_code)
    local d1 = fc.days[1] or {}
    local uv = fc.now_uv
    local sr = (d1.sunrise or ''):match('T(%d%d:%d%d)') or (d1.sunrise or '')
    local ss = (d1.sunset or ''):match('T(%d%d:%d%d)') or (d1.sunset or '')
    local metrics = 'Feels ' .. deg(fc.now_feel) ..
                    '   Hum ' .. (fc.now_hum or '-') .. '%' ..
                    '   Wind ' .. (fc.now_wind or '-') .. ' km/h'
    local mins = age // 60
    local age_str = mins < 90 and ('updated ' .. mins .. ' min ago') or ('updated ' .. (mins // 60) .. ' h ago')

    if not is_land then
      -- Portrait: header, current, 3 days, then the full Details card.
      g:text(24 + ox, 18 + oy, place_str, { font = font('large') })
      g:text(25 + ox, 18 + oy, place_str, { font = font('large') })
      local bx = X.big_number(g, temp, 24 + ox, 58 + oy, 120)
      g:text(bx + 4, 60 + oy, '°' .. fc.unit, { font = font('large') })
      X.icon(g, kind, W - 170 + ox, 54 + oy, 140)
      g:text(24 + ox, 184 + oy, text, { font = font('large') })
      g:text(24 + ox, 220 + oy, metrics, { font = font('small') })
      g:line(24 + ox, 246 + oy, W - 24 + ox, 246 + oy)
      g:text(24 + ox, 254 + oy,
        'Today ' .. deg(d1.lo) .. ' / ' .. deg(d1.hi) ..
        '   rain ' .. (d1.rain or 0) .. '%', { font = font('medium') })
      g:line(24 + ox, 284 + oy, W - 24 + ox, 284 + oy)
      for k = 2, math.min(4, #fc.days) do
        local d = fc.days[k]
        local ry = 292 + (k - 2) * 64 + oy
        g:text(24 + ox, ry + 4, X.weekday(d.date), { font = font('large') })
        X.icon(g, X.kind(d.code), 150 + ox, ry + 2, 52)
        g:text(250 + ox, ry + 4, deg(d.lo) .. ' / ' .. deg(d.hi), { font = font('large') })
        g:text(250 + ox, ry + 36, 'rain ' .. (d.rain or 0) .. '%', { font = font('small') })
        g:line(24 + ox, ry + 62, W - 24 + ox, ry + 62)
      end
      g:line(24 + ox, 492 + oy, W - 24 + ox, 492 + oy)
      g:text(24 + ox, 496 + oy, 'Details', { font = font('small') })
      local ly = 520 + oy
      -- Roomier label/value pairs: 22px apart, rows 50px apart.
      g:text(24 + ox, ly, 'UV', { font = font('small') })
      g:text(24 + ox, ly + 22, uv and tostring(uv) or '-', { font = font('medium') })
      g:text(24 + ox, ly + 50, 'Humidity', { font = font('small') })
      g:text(24 + ox, ly + 72, (fc.now_hum or '-') .. '%', { font = font('medium') })
      g:text(24 + ox, ly + 100, 'Sunrise', { font = font('small') })
      g:text(24 + ox, ly + 122, sr ~= '' and sr or '-', { font = font('medium') })
      local rx = 250 + ox
      g:text(rx, ly, 'Wind', { font = font('small') })
      g:text(rx, ly + 22, (fc.now_wind or '-') .. ' km/h', { font = font('medium') })
      g:text(rx, ly + 50, 'Pressure', { font = font('small') })
      g:text(rx, ly + 72, '1013 hPa', { font = font('medium') })
      g:text(rx, ly + 100, 'Sunset', { font = font('small') })
      g:text(rx, ly + 122, ss ~= '' and ss or '-', { font = font('medium') })
      X.moon(g, W - 70 + ox, ly + 52, 26)
      g:text(W - 130 + ox, ly + 100, 'New Moon', { font = font('small') })
      g:text(24 + ox, H - 30 + oy, age_str, { font = font('small') })
    else
      -- Landscape: current at top-left, 4-day rows, compact Details strip.
      g:text(24 + ox, 12 + oy, place_str, { font = font('large') })
      g:text(25 + ox, 12 + oy, place_str, { font = font('large') })
      local bx = X.big_number(g, temp, 24 + ox, 46 + oy, 76)
      g:text(bx + 4, 48 + oy, '°' .. fc.unit, { font = font('large') })
      X.icon(g, kind, W - 170 + ox, 36 + oy, 110)
      g:text(300 + ox, 48 + oy, text, { font = font('large') })
      g:text(300 + ox, 88 + oy, metrics, { font = font('small') })
      g:line(24 + ox, 136 + oy, W - 24 + ox, 136 + oy)
      g:text(24 + ox, 144 + oy,
        'Today ' .. deg(d1.lo) .. ' / ' .. deg(d1.hi) ..
        '   rain ' .. (d1.rain or 0) .. '%', { font = font('medium') })
      for k = 2, math.min(5, #fc.days) do
        local d = fc.days[k]
        local ry = 176 + (k - 2) * 36 + oy
        g:text(24 + ox, ry + 4, X.weekday(d.date), { font = font('medium') })
        X.icon(g, X.kind(d.code), 130 + ox, ry + 2, 28)
        g:text(172 + ox, ry + 4, deg(d.lo) .. ' / ' .. deg(d.hi), { font = font('medium') })
        g:text(320 + ox, ry + 6, 'rain ' .. (d.rain or 0) .. '%', { font = font('small') })
        g:line(24 + ox, ry + 34, W - 24 + ox, ry + 34)
      end
      local dy = 326 + oy
      g:line(24 + ox, dy, W - 24 + ox, dy)
      g:text(24 + ox, dy + 4, 'Details', { font = font('small') })
      local line1 = 'UV ' .. (uv and tostring(uv) or '-') ..
                    '     Humidity ' .. (fc.now_hum or '-') .. '%' ..
                    '     Sunrise ' .. (sr ~= '' and sr or '-')
      local line2 = 'Wind ' .. (fc.now_wind or '-') .. ' km/h' ..
                    '     Pressure 1013 hPa' ..
                    '     Sunset ' .. (ss ~= '' and ss or '-')
      g:text(24 + ox, dy + 26, line1, { font = font('small') })
      g:text(24 + ox, dy + 54, line2, { font = font('small') })
      X.moon(g, W - 50 + ox, dy + 40, 14)
      g:text(24 + ox, H - 22 + oy, age_str, { font = font('small') })
    end
  end)
  if not ok then
    pcall(function()
      g:text(10 + ox, H - 40 + oy, 'lock err: ' .. tostring(err):sub(1, 60), { font = font('small') })
    end)
  end
end

function on_load() end
function on_tick() end
-- Return false so the system receives the input (don't block unlock gestures)
function on_input() return false end
