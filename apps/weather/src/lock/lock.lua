-- XT Weather lock screen entry.
-- Shown as the device wallpaper / lock screen via XTOS Licorice lockscreen API.
-- Reads forecast.txt written by the main app. Refreshes if data is over 1 hour old.
-- Does NOT depend on gamekit - works as a standalone XTOS lockscreen script.
-- Based on the lockscreen architecture from touch-licorice-apps by Omer Faruk Inel.

local W, H = 480, 800
local STALE_S = 60 * 60   -- 1 hour: refresh threshold
local UA = 'XT Weather/1.4.2 (https://github.com/Valblasp/XT-Weather)'
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

local function deg(v) return v and (tostring(v) .. '\xC2\xB0') or '-' end

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
        pcall(function() ctx:invalidate() end)
      end)
    end)
  end)
end

function on_draw(c, gg)
  if not gg then return end
  local ok, err = pcall(function()
    gg:clear(0)

    local fc = X.parse_cache(read('forecast.txt'))
    if not fc then
      gg:text(24, 380, 'XT Weather: open the app once to set a city.', { font = font('medium') })
      return
    end

    -- Refresh if stale
    local age = now_sec() - (fc.updated or 0)
    if age > STALE_S then try_refresh(fc) end

    -- City name (bold trick: draw twice offset by 1px)
    local place_str = tostring(fc.place)
    gg:text(24, 24, place_str, { font = font('large') })
    gg:text(25, 24, place_str, { font = font('large') })

    -- Big temperature (seven-segment) + unit
    local temp = fc.now_t and tostring(fc.now_t) or '-'
    local bx = X.big_number(gg, temp, 24, 90, 150)
    gg:text(bx + 4, 86, '\xC2\xB0' .. fc.unit, { font = font('large') })

    -- Weather icon (right side)
    local kind, text = X.kind(fc.now_code)
    X.icon(gg, kind, W - 190, 80, 170)

    -- Weather description
    gg:text(24, 262, text, { font = font('large') })

    -- Single metrics line: feels / humidity / wind
    local metrics = 'Feels ' .. deg(fc.now_feel) ..
                    '   Hum ' .. (fc.now_hum or '-') .. '%' ..
                    '   Wind ' .. (fc.now_wind or '-') .. ' km/h'
    gg:text(24, 300, metrics, { font = font('small') })
    gg:line(24, 334, W - 24, 334)

    -- Today summary
    local d1 = fc.days[1]
    if d1 then
      gg:text(24, 354,
        'Today ' .. deg(d1.lo) .. ' / ' .. deg(d1.hi) ..
        '   rain ' .. (d1.rain or 0) .. '%',
        { font = font('medium') })
    end
    gg:line(24, 388, W - 24, 388)

    -- Next 3 days
    for k = 2, math.min(4, #fc.days) do
      local d = fc.days[k]
      local ry = 408 + (k - 2) * 100
      gg:text(24, ry + 28, X.weekday(d.date), { font = font('large') })
      X.icon(gg, (X.kind(d.code)), 150, ry, 80)
      gg:text(260, ry + 28, deg(d.lo) .. ' / ' .. deg(d.hi), { font = font('large') })
      gg:text(260, ry + 60, 'rain ' .. (d.rain or 0) .. '%', { font = font('small') })
    end

    -- Footer: data age
    local mins = age // 60
    local age_str = mins < 90 and ('updated ' .. mins .. ' min ago') or ('updated ' .. (mins // 60) .. ' h ago')
    gg:text(24, H - 36, age_str, { font = font('small') })
  end)
  if not ok then
    pcall(function()
      gg:text(10, H - 40, 'lock err: ' .. tostring(err):sub(1, 60), { font = font('small') })
    end)
  end
end

function on_load() end
function on_tick() end
-- Return false so the system receives the input (don't block unlock gestures)
function on_input() return false end
