-- Left ⌘ tapped alone -> 英数 (JIS Eisu); right ⌘ tapped alone -> かな (JIS Kana).
-- Held past the threshold, or combined with another key/click, each ⌘ stays a
-- plain modifier. Replaces the single Karabiner-Elements rule this repo carried.

local LEFT_CMD, RIGHT_CMD = 55, 54                     -- physical keycodes
local SEND = { [LEFT_CMD] = 102, [RIGHT_CMD] = 104 }   -- 英数 / かな keycodes
local HOLD_THRESHOLD = 0.2                             -- s; longer press = plain modifier

local trackedKey, pressedAt, usedAsModifier = nil, 0, false

local function tap(code)
  hs.eventtap.event.newKeyEvent({}, code, true):post()
  hs.eventtap.event.newKeyEvent({}, code, false):post()
end

-- Persist the eventtaps in a global so Hammerspoon's GC cannot collect them;
-- a local reference gets garbage-collected and the taps silently stop firing.
EisuKana = EisuKana or {}
if EisuKana.use then EisuKana.use:stop() end
if EisuKana.flags then EisuKana.flags:stop() end

-- Any key or mouse press while a ⌘ is held means that ⌘ was used as a modifier.
EisuKana.use = hs.eventtap.new({
  hs.eventtap.event.types.keyDown,
  hs.eventtap.event.types.leftMouseDown,
  hs.eventtap.event.types.rightMouseDown,
  hs.eventtap.event.types.otherMouseDown,
}, function()
  if trackedKey then usedAsModifier = true end
  return false
end)

EisuKana.flags = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(e)
  local code = e:getKeyCode()
  local isCmd = code == LEFT_CMD or code == RIGHT_CMD
  local f = e:getFlags()
  local cmdDown = f.cmd
  local onlyCmd = f.cmd and not (f.shift or f.ctrl or f.alt or f.fn)
  local now = hs.timer.secondsSinceEpoch()

  if isCmd and onlyCmd and trackedKey == nil then       -- a lone ⌘ went down, no other modifier
    trackedKey, pressedAt, usedAsModifier = code, now, false
  elseif isCmd and not cmdDown and trackedKey == code then  -- the tracked ⌘ released, no ⌘ left
    trackedKey = nil
    if not usedAsModifier and now - pressedAt < HOLD_THRESHOLD then
      tap(SEND[code])
    end
  else                                                  -- second ⌘, other modifier, or mismatch
    if trackedKey then usedAsModifier = true end
    if isCmd and not cmdDown then trackedKey = nil end
  end
  return false
end)

EisuKana.use:start()
EisuKana.flags:start()
