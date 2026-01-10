-- RoarGuild v1.2
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariablesPerCharacter: ROGUDB, WorkThatGodBodDB
-- Author: babunigaming
-- Slash commands: /rogu, /godbod

-------------------------------------------------
-- Utilities
-------------------------------------------------
local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RoarGuild:|r "..text)
  end
end

local function godChat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000GodBod:|r "..text)
  end
end

local function split_cmd(raw)
  local s = raw or ""
  s = string.gsub(s, "^%s+", "")
  local _, _, cmd, rest = string.find(s, "^(%S+)%s*(.*)$")
  if not cmd then cmd = "" rest = "" end
  return string.lower(cmd), rest
end

-------------------------------------------------
-- Databases (PER CHARACTER)
-------------------------------------------------
local function ensureROGUDB()
  if type(ROGUDB) ~= "table" then ROGUDB = {} end
  if type(ROGUDB.slots) ~= "table" then ROGUDB.slots = {} end
  if ROGUDB.enabled == nil then ROGUDB.enabled = true end
  return ROGUDB
end

local function ensureGodDB()
  if type(WorkThatGodBodDB) ~= "table" then WorkThatGodBodDB = {} end
  if type(WorkThatGodBodDB.slots) ~= "table" then WorkThatGodBodDB.slots = {} end
  if WorkThatGodBodDB.enabled == nil then WorkThatGodBodDB.enabled = true end
  if not WorkThatGodBodDB.cooldown then WorkThatGodBodDB.cooldown = 60 end
  if not WorkThatGodBodDB.chance then WorkThatGodBodDB.chance = 100 end
  return WorkThatGodBodDB
end

-------------------------------------------------
-- RoarGuild (Emotes)
-------------------------------------------------
local EMOTES = { "ROAR","CHARGE","CHEER","FLEX" }
local WATCH_SLOTS = {}
local ENABLED = true

local function pick(t)
  return t[math.random(1, table.getn(t))]
end

local function doEmote(token)
  if DoEmote then DoEmote(token) end
end

local function tryRoar(cfg)
  if not ENABLED then return end
  local now = GetTime()
  cfg.last = cfg.last or 0
  if now - cfg.last < cfg.cd then return end
  cfg.last = now
  if math.random(1,100) <= cfg.chance then
    doEmote(pick(EMOTES))
  end
end

-------------------------------------------------
-- Rested XP (FORWARD DECLARED)
-------------------------------------------------
local reportRestedXP
reportRestedXP = function()
  local r = GetXPExhaustion()
  if not r then chat("No rest.") return end
  local m = UnitXPMax("player")
  if not m or m == 0 then chat("No XP data.") return end
  local bubbles = math.floor((r * 20) / m + 0.5)
  if bubbles > 30 then bubbles = 30 end
  chat("Rest: "..bubbles.." bubbles ("..r.." XP)")
end

-------------------------------------------------
-- GodBod (Exercises)
-------------------------------------------------
local EXERCISES = {
  "Roll your shoulders slowly back ten times. Let the neck float.",
  "Stand up. Shake out your legs for twenty seconds.",
  "Look far away. Blink slowly ten times.",
  "Squeeze your shoulder blades together for five breaths.",
  "Drink water. Deep breath in, slow breath out.",
  "Stand tall. Reach both arms overhead like you mean it.",
  "Rotate your wrists and ankles. Loosen the hinges.",
  "Turn your head left and right. No forcing.",
  "Do ten calm bodyweight squats.",
  "March in place for thirty seconds.",
  "Move joints gently, no force."
}

local GOD_SLOTS = {}
local GOD_LAST = 0
local GOD_COOLDOWN = 60
local GOD_CHANCE = 100
local GOD_ENABLED = true

local function triggerExercise()
  if not GOD_ENABLED then return end
  local now = GetTime()
  if now - GOD_LAST < GOD_COOLDOWN then return end
  GOD_LAST = now
  if math.random(1,100) <= GOD_CHANCE then
    godChat(EXERCISES[math.random(1,#EXERCISES)])
  end
end

-------------------------------------------------
-- Single UseAction Hook (CRITICAL FIX)
-------------------------------------------------
local Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  for _, cfg in pairs(WATCH_SLOTS) do
    if cfg.slot == slot then tryRoar(cfg) end
  end
  if GOD_SLOTS[slot] then triggerExercise() end
  return Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- /rogu Slash Command
-------------------------------------------------
SLASH_ROGU1 = "/rogu"
SlashCmdList["ROGU"] = function(raw)
  local db = ensureROGUDB()
  WATCH_SLOTS = db.slots
  ENABLED = db.enabled

  local cmd, rest = split_cmd(raw)

  local _,_,idx = string.find(cmd, "^slot(%d+)$")
  if idx then
    local slot = tonumber(rest)
    if slot then
      WATCH_SLOTS[tonumber(idx)] = { slot=slot, chance=100, cd=6 }
      chat("instance"..idx.." watching slot "..slot)
    end
    return
  end

  if cmd == "info" then
    chat("enabled: "..tostring(ENABLED))
    for i,cfg in pairs(WATCH_SLOTS) do
      chat("instance"..i..": slot "..cfg.slot.." | "..cfg.chance.."% | "..cfg.cd.."s")
    end
    return
  end

  if cmd == "rexp" then reportRestedXP() return end
end

-------------------------------------------------
-- /godbod Slash Command
-------------------------------------------------
SLASH_GODBOD1 = "/godbod"
SlashCmdList["GODBOD"] = function(raw)
  local db = ensureGodDB()
  GOD_SLOTS = db.slots
  GOD_ENABLED = db.enabled
  GOD_COOLDOWN = db.cooldown
  GOD_CHANCE = db.chance

  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n then GOD_SLOTS[n] = true godChat("slot "..n.." added") end
    return
  end
end

-------------------------------------------------
-- Init / Save
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function(_,e)
  if e=="PLAYER_LOGIN" then
    math.randomseed(GetTime())
    local db = ensureROGUDB()
    WATCH_SLOTS = db.slots
    ENABLED = db.enabled

    local g = ensureGodDB()
    GOD_SLOTS = g.slots
    GOD_ENABLED = g.enabled
    GOD_COOLDOWN = g.cooldown
    GOD_CHANCE = g.chance
  end
end)
