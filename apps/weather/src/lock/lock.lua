-- XT Weather lock screen entry.
-- Shown as the device wallpaper / lock screen via XTOS Licorice lockscreen API.
-- Reads forecast.txt written by the main app. Refreshes if data is over 1 hour old.
-- Does NOT depend on gamekit - works as a standalone XTOS lockscreen script.
-- Based on the lockscreen architecture from touch-licorice-apps by Omer Faruk Inel.

local W, H = 480, 800
local STALE_S = 60 * 60   -- 1 hour: refresh threshold
local UA = 'XT Weather/1.5.3 (https://github.com/Valblasp/XT-Weather)'
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
      g:text(24 + ox, 380 + oy, 'XT Weather: open the app once to set a city.', { font = font('medium') })
      return
    end

    -- Refresh if stale (> 1 hour)
    local age = now_sec() - (fc.updated or 0)
    if age > STALE_S then try_refresh(fc) end

    -- City name (bold effect: draw twice offset by 1px)
    local place_str = tostring(fc.place)
    g:text(24 + ox, 24 + oy, place_str, { font = font('large') })
    g:text(25 + ox, 24 + oy, place_str, { font = font('large') })

    -- Big temperature (seven-segment) + unit
    local temp = fc.now_t and tostring(fc.now_t) or '-'
    local bx = X.big_number(g, temp, 24 + ox, 90 + oy, 150)
    g:text(bx + 4, 86 + oy, '°' .. fc.unit, { font = font('large') })

    -- Weather icon (right side)
    local kind, text = X.kind(fc.now_code)
    X.icon(g, kind, W - 190 + ox, 80 + oy, 170)

    -- Weather description
    g:text(24 + ox, 262 + oy, text, { font = font('large') })

    -- Single metrics line: feels / humidity / wind
    local metrics = 'Feels ' .. deg(fc.now_feel) ..
                    '   Hum ' .. (fc.now_hum or '-') .. '%' ..
                    '   Wind ' .. (fc.now_wind or '-') .. ' km/h'
    g:text(24 + ox, 300 + oy, metrics, { font = font('small') })
    g:line(24 + ox, 334 + oy, W - 24 + ox, 334 + oy)

    -- Today summary
    local d1 = fc.days[1]
    if d1 then
      g:text(24 + ox, 354 + oy,
        'Today ' .. deg(d1.lo) .. ' / ' .. deg(d1.hi) ..
        '   rain ' .. (d1.rain or 0) .. '%',
        { font = font('medium') })
    end
    g:line(24 + ox, 388 + oy, W - 24 + ox, 388 + oy)

    -- Next 3 days
    for k = 2, math.min(4, #fc.days) do
      local d = fc.days[k]
      local ry = 408 + (k - 2) * 100 + oy
      g:text(24 + ox, ry + 28, X.weekday(d.date), { font = font('large') })
      X.icon(g, (X.kind(d.code)), 150 + ox, ry, 80)
      g:text(260 + ox, ry + 28, deg(d.lo) .. ' / ' .. deg(d.hi), { font = font('large') })
      g:text(260 + ox, ry + 60, 'rain ' .. (d.rain or 0) .. '%', { font = font('small') })
    end

    -- Footer: data age
    local mins = age // 60
    local age_str = mins < 90 and ('updated ' .. mins .. ' min ago') or ('updated ' .. (mins // 60) .. ' h ago')
    g:text(24 + ox, H - 36 + oy, age_str, { font = font('small') })
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
