-- RoarGuild + GodBod Combined v1.1
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariables: ROGUDB, WorkThatGodBodDB

-------------------------------------------------
-- Globals / Config
-------------------------------------------------
local WATCH_SLOTS = {}
local WATCH_MODE = false
local ENABLED = true
local LAST_ROAR_TIME = 0
local LAST_REMINDER_TIME = 0
local ROAR_REMINDER_INTERVAL = 420
local ROAR_REMINDER_CD = 73

local GOD_WATCH_SLOTS = {}
local GOD_WATCH_MODE = false
local GOD_LAST_TRIGGER_TIME = 0
local GOD_COOLDOWN = 60
local GOD_CHANCE = 100
local GOD_ENABLED = true

-------------------------------------------------
-- Utility Functions
-------------------------------------------------
local function roarChat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RoarGuild:|r "..text)
  end
end

local function godChat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000GodBod:|r "..text)
  end
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1,n)]
end

local function split_cmd(raw)
  local s = raw or ""
  s = string.gsub(s, "^%s+", "")
  local _, _, cmd, rest = string.find(s, "^(%S+)%s*(.*)$")
  if not cmd then cmd = "" rest = "" end
  return cmd, rest
end

-------------------------------------------------
-- ROGU DB
-------------------------------------------------
local function roarEnsureDB()
  if type(ROGUDB) ~= "table" then ROGUDB = {} end
  if type(ROGUDB.slots) ~= "table" then ROGUDB.slots = {} end
  if type(ROGUDB.emotes) ~= "table" then ROGUDB.emotes = { [1] = { emote = "ROAR" } } end
  return ROGUDB
end

local function roarEnsureLoaded()
  local db = roarEnsureDB()
  WATCH_SLOTS = db.slots or {}
  for _, cfg in pairs(WATCH_SLOTS) do
    cfg.chance = cfg.chance or 100
    cfg.cd = cfg.cd or 6
    cfg.last = cfg.last or 0
  end
  db.emotes = db.emotes or { [1] = { emote = "ROAR" } }
  ENABLED = (db.enabled ~= nil) and db.enabled or true
end

local function getBattleEmotes()
  local emotes = roarEnsureDB().emotes
  local t = {}
  for _, entry in pairs(emotes) do
    t[#t+1] = entry.emote
  end
  return t
end

local function addRoarEmote(name)
  if not name or name == "" then return end
  local emotes = roarEnsureDB().emotes
  name = name:upper()
  for _, entry in pairs(emotes) do
    if entry.emote == name then return end
  end
  local nextID = 1
  for id in pairs(emotes) do if id >= nextID then nextID = id + 1 end end
  emotes[nextID] = { emote = name }
  roarChat("Added emote '"..name.."' with ID "..nextID)
end

local function listRoarEmotes()
  local emotes = roarEnsureDB().emotes
  roarChat("Emote list:")
  for id, entry in pairs(emotes) do
    roarChat("ID "..id..": "..entry.emote)
  end
end

local function performEmote(token)
  if DoEmote then
    DoEmote(token)
  else
    SendChatMessage("makes a battle cry!", "EMOTE")
  end
end

local function doBattleEmoteForSlot(cfg)
  if not ENABLED or not cfg then return end
  local now = GetTime()
  cfg.last = cfg.last or 0
  if now - cfg.last < cfg.cd then return end
  cfg.last = now
  if math.random(1,100) <= cfg.chance then
    local e = pick(getBattleEmotes())
    if e then
      performEmote(e)
      LAST_ROAR_TIME = now
    end
  end
end

local function reportRestedXP()
  local r = GetXPExhaustion()
  if not r then roarChat("No rest."); return end
  local m = UnitXPMax("player")
  if not m or m == 0 then roarChat("No XP data."); return end
  local bubbles = math.floor((r * 20) / m + 0.5)
  if bubbles > 30 then bubbles = 30 end
  roarChat("Rest: "..bubbles.." bubbles ("..r.." XP)")
end

-------------------------------------------------
-- GodBod DB
-------------------------------------------------
local function godEnsureDB()
  if type(WorkThatGodBodDB) ~= "table" then WorkThatGodBodDB = {} end
  if type(WorkThatGodBodDB.slots) ~= "table" then WorkThatGodBodDB.slots = {} end
  return WorkThatGodBodDB
end

local function godEnsureLoaded()
  local db = godEnsureDB()
  GOD_WATCH_SLOTS = db.slots or {}
  GOD_COOLDOWN = db.cooldown or GOD_COOLDOWN
  GOD_CHANCE = db.chance or GOD_CHANCE
  GOD_ENABLED = (db.enabled ~= nil) and db.enabled or true
end

local EXERCISES = {
  "Roll your shoulders slowly back ten times. Let the neck float.",
  "Stand up. Shake out your legs for twenty seconds.",
  "Look far away. Blink slowly ten times.",
  "Squeeze your shoulder blades together for five breaths.",
  "Drink water. Deep breath in, slow breath out."
  -- truncated for brevity
}

local function triggerExercise()
  if not GOD_ENABLED then return end
  local now = GetTime()
  if now - GOD_LAST_TRIGGER_TIME < GOD_COOLDOWN then return end
  GOD_LAST_TRIGGER_TIME = now
  if math.random(1,100) <= GOD_CHANCE then
    local msg = pick(EXERCISES)
    if msg then godChat(msg) end
  end
end

-------------------------------------------------
-- Hook UseAction
-------------------------------------------------
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  roarEnsureLoaded()
  godEnsureLoaded()
  local now = GetTime()

  for _, cfg in pairs(WATCH_SLOTS) do
    if cfg.slot == slot then doBattleEmoteForSlot(cfg) end
  end

  if ENABLED and slot and slot >= 1 and slot <= 200 then
    if math.random(1,1000) <= 5 then
      local e = pick(getBattleEmotes())
      if e then performEmote(e); LAST_ROAR_TIME = now end
    end
  end

  if ENABLED and LAST_ROAR_TIME > 0 then
    if now - LAST_ROAR_TIME >= ROAR_REMINDER_INTERVAL and now - LAST_REMINDER_TIME >= ROAR_REMINDER_CD then
      roarChat("You have not roared in a while.")
      LAST_REMINDER_TIME = now
    end
  end

  if GOD_WATCH_SLOTS[slot] then triggerExercise() end

  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- Slash Commands
-------------------------------------------------
local function initSlashCommands()
  -- /rogu
  SLASH_ROGU1 = "/rogu"
  SlashCmdList["ROGU"] = function(raw)
    roarEnsureLoaded()
    local cmd, rest = split_cmd(raw)

    local _, _, slotIndex = string.find(cmd, "^slot(%d+)$")
    if slotIndex then
      local instance = tonumber(slotIndex)
      local slot = tonumber(rest)
      if instance and slot then
        WATCH_SLOTS[instance] = WATCH_SLOTS[instance] or {}
        WATCH_SLOTS[instance].slot = slot
        WATCH_SLOTS[instance].chance = WATCH_SLOTS[instance].chance or 100
        WATCH_SLOTS[instance].cd = WATCH_SLOTS[instance].cd or 6
        WATCH_SLOTS[instance].last = 0
        roarChat("instance"..instance.." watching slot "..slot)
      else
        roarChat("usage: /rogu slotX <slot>")
      end
      return
    end

    if cmd == "emote" then addRoarEmote(rest); return end
    if cmd == "emotelist" then listRoarEmotes(); return end
    if cmd == "rexp" then reportRestedXP(); return end
    if cmd == "on" then ENABLED = true; roarChat("enabled"); return end
    if cmd == "off" then ENABLED = false; roarChat("disabled"); return end
    if cmd == "watch" then WATCH_MODE = not WATCH_MODE; roarChat("watch mode "..(WATCH_MODE and "ON" or "OFF")); return end
    if cmd == "reset" then WATCH_SLOTS = {}; roarEnsureDB().slots = WATCH_SLOTS; roarChat("all instances cleared"); return end
    if cmd == "info" then
      roarChat("enabled: "..tostring(ENABLED))
      for i,cfg in pairs(WATCH_SLOTS) do
        roarChat("instance"..i..": slot "..cfg.slot.." | chance "..cfg.chance.."% | cd "..cfg.cd.."s")
      end
      return
    end
    if cmd == "roar" then
      local e = pick(getBattleEmotes())
      if e then performEmote(e); LAST_ROAR_TIME = GetTime() end
      return
    end

    roarChat("/rogu slotX <n> | watch | info | reset | on | off | emote <name> | emotelist | roar | rexp")
  end

  -- /godbod
  SLASH_GODBOD1 = "/godbod"
  SlashCmdList["GODBOD"] = function(raw)
    godEnsureLoaded()
    local cmd, rest = split_cmd(raw)
    if cmd == "slot" then local n = tonumber(rest); if n then GOD_WATCH_SLOTS[n]=true; godChat("watching slot "..n) end return end
    if cmd == "unslot" then local n = tonumber(rest); if n then GOD_WATCH_SLOTS[n]=nil; godChat("removed slot "..n) end return end
    if cmd == "clear" then GOD_WATCH_SLOTS={}; godEnsureDB().slots=GOD_WATCH_SLOTS; godChat("all slots cleared") end
    if cmd == "watch" then GOD_WATCH_MODE = not GOD_WATCH_MODE; godChat("watch mode "..(GOD_WATCH_MODE and "ON" or "OFF")) end
    if cmd == "chance" then local n=tonumber(rest); if n then GOD_CHANCE=n; godEnsureDB().chance=n; godChat("chance "..n.."%") end end
    if cmd == "cd" then local n=tonumber(rest); if n then GOD_COOLDOWN=n; godEnsureDB().cooldown=n; godChat("cooldown "..n.."s") end end
    if cmd == "on" then GOD_ENABLED=true; godEnsureDB().enabled=true; godChat("enabled.") end
    if cmd == "off" then GOD_ENABLED=false; godEnsureDB().enabled=false; godChat("disabled.") end
    if cmd == "info" then
      local count=0; for _ in pairs(GOD_WATCH_SLOTS) do count=count+1 end
      godChat("slots watched: "..count.." | chance: "..GOD_CHANCE.."% | cooldown: "..GOD_COOLDOWN.."s | enabled: "..tostring(GOD_ENABLED))
    end
  end
end

-------------------------------------------------
-- Event Frame / Initialization
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event)
  if event=="PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime()*1000))
    math.random()
    roarEnsureLoaded()
    godEnsureLoaded()
    initSlashCommands()
  elseif event=="PLAYER_LOGOUT" then
    local db = roarEnsureDB()
    db.slots = WATCH_SLOTS
    db.enabled = ENABLED
    db.emotes = roarEnsureDB().emotes

    local goddb = godEnsureDB()
    goddb.slots = GOD_WATCH_SLOTS
    goddb.cooldown = GOD_COOLDOWN
    goddb.chance = GOD_CHANCE
    goddb.enabled = GOD_ENABLED
  end
end)
