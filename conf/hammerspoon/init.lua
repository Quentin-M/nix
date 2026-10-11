-- Volume up/down keys (Razer dial) drive the Wave Link "Speakers/Headphones" mix whenever the
-- output device has no volume control of its own (Scarlett 6i6). Talks to Wave Link's
-- local JSON-RPC websocket - the Stream Deck API, which needs Origin streamdeck:// - via websocat.
hs.autoLaunch(true)
hs.dockIcon(false)
require("hs.ipc") -- CLI: /Applications/Hammerspoon.app/Contents/Frameworks/hs/hs -c '<lua>'

local MIX, STEP = "Speakers/Headphones", 0.05
local WEBSOCAT = "/etc/profiles/per-user/" .. os.getenv("USER") .. "/bin/websocat"

local ws, buf, pending, nextId = nil, "", {}, 0

local function onOutput(_, out)
  buf = buf .. out
  for line in buf:gmatch("([^\n]*)\n") do
    -- A Lua error here would stop the task's streaming callback for good.
    local ok, err = pcall(function()
      local msg = hs.json.decode(line)
      local cb = msg and msg.id and pending[msg.id]
      if cb then pending[msg.id] = nil; cb(msg.result) end
    end)
    if not ok then print("wavelink: " .. tostring(err)) end
  end
  buf = buf:match("[^\n]*$")
  return true
end

local function send(method, params, cb)
  if not (ws and ws:isRunning()) then
    buf, pending = "", {}
    ws = hs.task.new(WEBSOCAT, nil, onOutput, {"-t", "--origin", "streamdeck://", "ws://127.0.0.1:1884"})
    ws:start()
  end
  nextId = nextId + 1
  pending[nextId] = cb
  ws:setInput(hs.json.encode({jsonrpc = "2.0", id = nextId, method = method, params = params}) .. "\n")
end

function adjust(key)
  send("getMixes", nil, function(r)
    for _, m in ipairs(r and r.mixes or {}) do
      if m.name == MIX then
        local p = {id = m.id, isMuted = not m.isMuted}
        if key ~= "MUTE" then
          p.isMuted = false
          p.level = math.max(0, math.min(1, m.level + (key == "SOUND_UP" and STEP or -STEP)))
        end
        send("setMix", p)
        hs.alert.closeAll()
        hs.alert.show(p.isMuted and "🔇" or string.format("🔊 %d%%", math.floor((p.level or m.level) * 100 + 0.5)), 0.5)
      end
    end
  end)
end

-- Mute key toggles the Scarlett's Monitor Outputs 1-2 (speakers) through Focusrite Control
-- Server's XML protocol, so Line 3-4 (headphones) keeps playing. Approve "q-hammerspoon"
-- once in Focusrite Control. Items 851/861 are the Monitor Output 1/2 mutes on the 6i6 2nd gen.
local FC_MUTES = {"851", "861"}
local fcDev, fcMuted = nil, false

local function fcFrame(xml) return string.format("Length=%06X %s", #xml, xml) end

local function fcConnect()
  fcDev, fcMuted = nil, false
  fcSocket = hs.socket.new(function(data, tag)
    if tag == 1 then -- "Length=XXXXXX " header, then the XML body
      fcSocket:read(tonumber(data:sub(8, 13), 16), 2)
      return
    end
    local dev = data:match('<device%-arrival><device id="(%d+)"')
    if dev then
      fcDev = dev
      fcSocket:write(fcFrame('<device-subscribe devid="' .. dev .. '" subscribe="true"/>'))
    end
    local v = data:match('<item id="' .. FC_MUTES[1] .. '" value="(%a+)"')
    if v then fcMuted = v == "true" end
    fcSocket:read(14, 1)
  end)
  fcSocket:connect("127.0.0.1", 49169, function()
    fcSocket:write(fcFrame('<client-details hostname="q-hammerspoon" client-key="q-hammerspoon-wl"/>'))
    fcSocket:read(14, 1)
  end)
end

function fcState() return string.format("dev=%s connected=%s muted=%s", fcDev, fcSocket:connected(), fcMuted) end

function fcToggle()
  fcMuted = not fcMuted
  local items = ""
  for _, id in ipairs(FC_MUTES) do items = items .. '<item id="' .. id .. '" value="' .. tostring(fcMuted) .. '"/>' end
  fcSocket:write(fcFrame('<set devid="' .. fcDev .. '">' .. items .. "</set>"))
  hs.alert.closeAll()
  hs.alert.show(fcMuted and "🔇 speakers" or "🔊 speakers", 0.5)
end

-- The server drops clients silent for ~3 s; reconnect if Focusrite Control restarts.
fcTimer = hs.timer.doEvery(2, function()
  if fcSocket and fcSocket:connected() then fcSocket:write(fcFrame("<keep-alive/>")) else fcConnect() end
end)
fcConnect()

volumeTap = hs.eventtap.new({hs.eventtap.event.types.systemDefined}, function(e)
  -- Any error must let the key through, never swallow input.
  local ok, handled = pcall(function()
    local k = e:systemKey()
    if k.key ~= "SOUND_UP" and k.key ~= "SOUND_DOWN" and k.key ~= "MUTE" then return false end
    local out = hs.audiodevice.defaultOutputDevice()
    if not out or out:volume() ~= nil then return false end
    if k.key == "MUTE" and fcDev and fcSocket:connected() then
      if k.down then fcToggle() end
      return true
    end
    if not hs.application.get("com.elgato.WaveLink3") then return false end
    if k.down then adjust(k.key) end
    return true
  end)
  return ok and handled
end):start()
