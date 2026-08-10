-- Pure logic for the ItemFinderPlus mod: no love, no game globals.
-- Everything here is unit-testable headless (lupa).
--
-- Mirrors the vanilla Item Finder behaviour where it matters:
--   * the detection radius is the same rectangle the original checks
--     (OverworldState:hasHiddenItemLeft, engine/items/itemfinder.asm
--     HiddenItemNear), so "in radius" here means the same thing it does
--     in the original game;
--   * picked-up items drop out via the same save.hiddenTaken keys the
--     engine writes on pickup ("<mapId>_<x>_<y>").

local Logic = {}

Logic.BURST_SECS = 0.9

-- Every tile twinkles on the same cadence, near or far.
Logic.CADENCE_SECS = 2

-- Vanilla ITEMFINDER near-check: X in (max(px-5,0), px+5], Y in
-- (max(py-5,0), py+4] (the clamp excludes coordinate 0 whenever the
-- player coordinate is <= 4, exactly like the original).
function Logic.isNear(px, py, hx, hy)
  return hx > math.max(px - 5, 0) and hx <= px + 5
     and hy > math.max(py - 5, 0) and hy <= py + 4
end

-- The unfound hidden items on a map: hiddenItems[mapId] minus taken.
function Logic.unfoundItems(hiddenItems, taken, mapId)
  local out = {}
  local list = hiddenItems and hiddenItems[mapId]
  if not list then return out end
  local takenMap = taken or {}
  for _, h in ipairs(list) do
    if not takenMap[mapId .. "_" .. h.x .. "_" .. h.y] then
      out[#out + 1] = h
    end
  end
  return out
end

-- Deterministic per-tile phase so bursts across a map never sync up.
function Logic.phase(x, y)
  local v = (x * 73856093) % 99991 + (y * 19349663) % 99991
  return (v % 9973) / 9973
end

-- Burst scheduling. state is a per-mod table keyed "<x>,<y>" ->
-- { mode = "far"|"near", next = wall-clock of the next burst,
--   startedAt = wall-clock the current burst opened (nil when idle) }.
--   * a fresh tile's first burst lands after a short staggered delay so
--     a newly loaded map "twinkles in" instead of flashing all at once;
--   * crossing the detection radius restarts the cadence promptly
--     (the radius switch is the signal that matters);
--   * every tile bursts every CADENCE_SECS; "near"/"far" still rides
--     along so the caller can size and fade the sparkle differently.
-- A burst is *not* a single-frame event: once opened it stays in the
-- returned list for the whole BURST_SECS window, so the caller renders
-- the fade across frames.  (A burst emitted only on its trigger frame
-- would have age 0 there and burstAlpha(0) == 0 -- scheduled forever,
-- visible never.)
-- Returns a list of currently-bursting tiles:
--   { x, y, item, mode, phase, startedAt }.
function Logic.tick(items, state, px, py, now)
  local bursts = {}
  for _, h in ipairs(items) do
    local key = h.x .. "," .. h.y
    local near = Logic.isNear(px, py, h.x, h.y)
    local mode = near and "near" or "far"
    local cadence = Logic.CADENCE_SECS
    local st = state[key]
    if not st then
      st = { mode = mode, next = now + Logic.phase(h.x, h.y) * 0.9 }
      state[key] = st
    elseif st.mode ~= mode then
      st.mode = mode
      st.startedAt = nil -- kill any in-flight burst; restart fresh
      st.next = now + 0.35
    end
    if now >= st.next then
      st.startedAt = now -- open the burst window
      st.next = now + cadence
    end
    local started = st.startedAt
    if started and now - started <= Logic.BURST_SECS then
      bursts[#bursts + 1] = {
        x = h.x, y = h.y, item = h.item, mode = mode,
        phase = Logic.phase(h.x, h.y), startedAt = started,
      }
    end
  end
  return bursts
end

-- Drop state for tiles that no longer exist (picked up, map changed).
function Logic.cleanup(state, items)
  local live = {}
  for _, h in ipairs(items) do live[h.x .. "," .. h.y] = true end
  for key in pairs(state) do
    if not live[key] then state[key] = nil end
  end
end

-- Burst envelope: fast attack (first 12%), then a soft linear fade.
-- Returns alpha in 0..1; 0 outside the burst window.
function Logic.burstAlpha(age)
  if age < 0 or age > Logic.BURST_SECS then return 0 end
  local t = age / Logic.BURST_SECS
  if t < 0.12 then return t / 0.12 end
  return 1 - (t - 0.12) / 0.88
end

-- Gentle growth then shrink over the burst.
function Logic.burstSize(age, base)
  if age < 0 or age > Logic.BURST_SECS then return base end
  local t = age / Logic.BURST_SECS
  return base * (1 + 0.35 * math.sin(t * math.pi))
end

return Logic
