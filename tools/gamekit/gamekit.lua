-- Shared UI + storage toolkit for the XT Weather mini app on the XTOS Licorice host.
-- tools/gamekit/bundle.py pastes this whole block in front of the app's entry script, because the
-- device host runs each app as one self-contained Lua state with no package loader.

local kit = {}

kit.W, kit.H = 480, 800

function kit.font(name) return ctx.fonts and ctx.fonts[name] end

function kit.width(f, s)
  local ok, w = pcall(function() return f:measure(s) end)
  return (ok and type(w) == 'number') and w or #tostring(s) * 11
end

function kit.line_h(name)
  local ok, h = pcall(function() return kit.font(name).line_height end)
  return (ok and tonumber(h)) or (name == 'large' and 30 or name == 'small' and 20 or 24)
end

function kit.drop_last(s) return (s:gsub('[%z\1-\127\192-\255][\128-\191]*$', '')) end

function kit.short(s, n)
  s = tostring(s)
  if #s <= n then return s end
  local t = s:sub(1, n)
  while #t > n - 1 or (#t > 0 and t:sub(-1):byte() >= 128 and not utf8.len(t)) do t = kit.drop_last(t) end
  return t .. '~'
end

function kit.wrap(s, fname, maxw)
  local f, out = kit.font(fname), {}
  for para in (tostring(s) .. '\n'):gmatch('([^\n]*)\n') do
    local line = ''
    for word in para:gmatch('[^ \t]+') do
      local cand = line == '' and word or (line .. ' ' .. word)
      if line ~= '' and kit.width(f, cand) > maxw then out[#out + 1] = line; line = word else line = cand end
    end
    out[#out + 1] = line
  end
  return out
end

function kit.read(name)
  local ok, s = pcall(function() return ctx.storage:read(name) end)
  return (ok and type(s) == 'string') and s or nil
end

function kit.write(name, s) pcall(function() ctx.storage:write(name, s) end) end

function kit.kv(s)
  local t = {}
  for k, v in (s or ''):gmatch('([%w_]+)=([^\n]*)') do t[k] = (v:gsub('%s+$', '')) end
  return t
end

function kit.now_ms() local ok, t = pcall(function() return ctx.clock:millis() end); return ok and tonumber(t) or nil end
function kit.refresh() pcall(function() ctx:invalidate() end) end

local moves = 0
function kit.moved() moves = moves + 1 end

local KEY_GAP_MS = 250
local last_key, last_key_ms = nil, nil
function kit.key_accepted(ev)
  local ph = ev.phase or ev.action or ev.state
  if ph == 'up' or ph == 'release' or ph == 'released' or ev.pressed == false or ev.down == false then return false end
  local t = tonumber(ev.time_ms) or kit.now_ms()
  if t and last_key == ev.key and last_key_ms and t - last_key_ms >= 0 and t - last_key_ms < KEY_GAP_MS then return false end
  last_key, last_key_ms = ev.key, t
  return true
end

------------------------------------------------------------------ boxes

local BOX_X, BOX_W, ROW_H, GAP = 20, kit.W - 40, 56, 10
local modal = nil

function kit.show(m) modal = m end
function kit.close() modal = nil end
function kit.modal() return modal end

local function modal_layout(m)
  local lines = {}
  if m.title then for _k, l in ipairs(kit.wrap(m.title, 'medium', BOX_W - 40)) do lines[#lines + 1] = { l, 'medium' } end end
  for _k, s in ipairs(m.lines or {}) do
    for _j, l in ipairs(kit.wrap(s, 'small', BOX_W - 40)) do lines[#lines + 1] = { l, 'small' } end
  end
  local th = 0
  for _k, l in ipairs(lines) do th = th + kit.line_h(l[2]) + 4 end
  local h = 20 + th + 14 + #m.rows * (ROW_H + GAP) + 10
  local y = math.max(60, math.floor((kit.H - h) / 2))
  local btns, by = {}, y + 20 + th + 14
  for _k, row in ipairs(m.rows) do
    local n = #row
    local bw = math.floor((BOX_W - 40 - (n - 1) * GAP) / n)
    for k, btn in ipairs(row) do
      btns[#btns + 1] = { x = BOX_X + 20 + (k - 1) * (bw + GAP), y = by, w = bw, h = ROW_H, b = btn }
    end
    by = by + ROW_H + GAP
  end
  return lines, btns, y, h
end

function kit.draw_modal(gg)
  local lines, btns, y, h = modal_layout(modal)
  gg:rect(BOX_X, y, BOX_W, h)
  gg:rect(BOX_X + 3, y + 3, BOX_W - 6, h - 6)
  local ty = y + 20
  for _k, l in ipairs(lines) do gg:text(BOX_X + 20, ty, l[1], { font = kit.font(l[2]) }); ty = ty + kit.line_h(l[2]) + 4 end
  for _k, bt in ipairs(btns) do
    local enabled = bt.b[3] ~= false
    kit.button(gg, bt.x, bt.y, bt.w, bt.h, enabled and bt.b[1] or ('(' .. bt.b[1] .. ')'), { line_width = enabled and 2 or 1 })
  end
end

function kit.tap_modal(x, y)
  if not modal then return false end
  local _l, btns, my, mh = modal_layout(modal)
  for _k, bt in ipairs(btns) do
    if x >= bt.x and x < bt.x + bt.w and y >= bt.y and y < bt.y + bt.h then
      if bt.b[3] ~= false then bt.b[2]() end
      return true
    end
  end
  if (y < my or y > my + mh) and modal.cancel then modal.cancel() end
  return true
end

function kit.button(gg, x, y, w, h, label, opts)
  opts = opts or {}
  local f = kit.font(opts.font or 'medium')
  gg:rect(x, y, w, h, { line_width = opts.line_width or 2 })
  local s = tostring(label)
  while #s > 1 and kit.width(f, s) > w - 10 do s = kit.drop_last(s) end
  gg:text(x + math.floor((w - kit.width(f, s)) / 2), y + math.floor((h - kit.line_h(opts.font or 'medium')) / 2), s, { font = f })
end

return kit
