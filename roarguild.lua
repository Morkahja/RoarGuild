-- RoarGuild v1.1
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariables: ROGUDB, WorkThatGodBodDB
-- Author: babunigaming
-- Slash commands: /rogu (RoarGuild), /godbod (GodBod)

-------------------------------------------------
-- ROARRunlimited / RoarGuild
-------------------------------------------------
local EMOTE_TOKENS_BATTLE = { "ROAR","CHARGE","CHEER","FLEX" }
local WATCH_SLOTS = {}   -- [instance] = { slot, chance=100, cd=6, last=0 }
local WATCH_MODE = false
local ENABLED = true

local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RoarGuild:|r " .. text)
  end
end

local function ensureDB()
  if type(ROGUDB) ~= "table" then ROGUDB = {} end
  return ROGUDB
end

local _loaded = false
local function ensureLoaded()
  if _loaded then return end
  local db = ensureDB()
  WATCH_SLOTS = db.slots or {}
  if db.enabled ~= nil then ENABLED = db.enabled end
  _loaded = true
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

local function performEmote(token)
  if DoEmote then DoEmote(token) else SendChatMessage("makes a battle cry!", "EMOTE") end
end

local function doBattleEmoteForSlot(cfg)
  if not ENABLED or not cfg then return end
  local now = GetTime()
  cfg.last = cfg.last or 0
  if now - cfg.last < cfg.cd then return end
  cfg.last = now
  if math.random(1,100) <= cfg.chance then
    local e = pick(EMOTE_TOKENS_BATTLE)
    if e then performEmote(e) end
  end
end

local function split_cmd(raw)
  local s = raw or ""
  s = string.gsub(s, "^%s+", "")
  local _, _, cmd, rest = string.find(s, "^(%S+)%s*(.*)$")
  if not cmd then cmd = "" rest = "" end
  return cmd, rest
end

-- Hook UseAction
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  ensureLoaded()
  if WATCH_MODE then chat("pressed slot " .. tostring(slot)) end
  for _, cfg in pairs(WATCH_SLOTS) do
    if cfg.slot == slot then doBattleEmoteForSlot(cfg) end
  end
  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-- /rogu Slash Commands
SLASH_ROGU1 = "/rogu"
SlashCmdList["ROGU"] = function(raw)
  ensureLoaded()
  local cmd, rest = split_cmd(raw)

  local _, _, slotIndex = string.find(cmd, "^slot(%d+)$")
  if slotIndex then
    local instance = tonumber(slotIndex)
    local slot = tonumber(rest)
    if instance and slot then
      WATCH_SLOTS[instance] = WATCH_SLOTS[instance] or { slot = slot, chance = 100, cd = 6, last = 0 }
      WATCH_SLOTS[instance].slot = slot
      ensureDB().slots = WATCH_SLOTS
      chat("instance"..instance.." watching slot "..slot)
    else
      chat("usage: /rogu slotX <slotNumber>")
    end
    return
  end

  local _, _, chanceIndex = string.find(cmd, "^chance(%d+)$")
  if chanceIndex then
    local instance = tonumber(chanceIndex)
    local n = tonumber(rest)
    local cfg = WATCH_SLOTS[instance]
    if cfg and n and n >= 0 and n <= 100 then
      cfg.chance = n
      chat("instance"..instance.." chance set to "..n.."%")
    else
      chat("usage: /rogu chanceX <0-100> (instance must exist)")
    end
    return
  end

  local _, _, timerIndex = string.find(cmd, "^timer(%d+)$")
  if timerIndex then
    local instance = tonumber(timerIndex)
    local n = tonumber(rest)
    local cfg = WATCH_SLOTS[instance]
    if cfg and n and n >= 0 then
      cfg.cd = n
      chat("instance"..instance.." cooldown set to "..n.."s")
    else
      chat("usage: /rogu timerX <seconds> (instance must exist)")
    end
    return
  end

  if cmd == "watch" then WATCH_MODE = not WATCH_MODE; chat("watch mode " .. (WATCH_MODE and "ON" or "OFF")); return end
  if cmd == "on" then ENABLED = true; ensureDB().enabled = true; chat("RoarGuild enabled"); return end
  if cmd == "off" then ENABLED = false; ensureDB().enabled = false; chat("RoarGuild disabled"); return end
  if cmd == "reset" then WATCH_SLOTS = {}; ensureDB().slots = {}; chat("all watched slots cleared"); return end
  if cmd == "info" then
    chat("enabled: "..tostring(ENABLED))
    local found = false
    for instance, cfg in pairs(WATCH_SLOTS) do
      found = true
      chat("instance"..instance..": slot "..cfg.slot.." | chance "..cfg.chance.."% | cd "..cfg.cd.."s")
    end
    if not found then chat("no watched slots") end
    return
  end

  chat("/rogu slotX <n> | chanceX <0-100> | timerX <sec> | watch | on | off | info | reset")
end

-------------------------------------------------
-- GodBod Integration
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

local GOD_WATCH_SLOTS = {}
local GOD_WATCH_MODE = false
local GOD_LAST_TRIGGER_TIME = 0
local GOD_COOLDOWN = 60
local GOD_CHANCE = 100
local GOD_ENABLED = true

local function godChat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000GodBod:|r " .. text)
  end
end

local function outputExercise(text)
  local roll = math.random(1, 100)
  if roll >= 99 then
    SendChatMessage(text, "CHANNEL", nil, 6)
  elseif roll >= 97 then
    SendChatMessage(text, "CHANNEL", nil, 1)
  elseif roll >= 95 then
    SendChatMessage(text, "PARTY")
  elseif roll >= 93 then
    SendChatMessage(text, "YELL")
  elseif roll >= 91 then
    SendChatMessage(text, "SAY")
  else
    godChat(text)
  end
end

local function ensureGodDB()
  if type(WorkThatGodBodDB) ~= "table" then WorkThatGodBodDB = {} end
  if type(WorkThatGodBodDB.slots) ~= "table" then WorkThatGodBodDB.slots = {} end
  return WorkThatGodBodDB
end

local _godLoaded = false
local function ensureGodLoaded()
  if _godLoaded then return end
  local db = ensureGodDB()
  GOD_WATCH_SLOTS = db.slots
  if db.cooldown then GOD_COOLDOWN = db.cooldown end
  if db.chance then GOD_CHANCE = db.chance end
  if db.enabled ~= nil then GOD_ENABLED = db.enabled end
  _godLoaded = true
end

local function triggerExercise()
  if not GOD_ENABLED then return end
  local now = GetTime()
  if now - GOD_LAST_TRIGGER_TIME < GOD_COOLDOWN then return end
  GOD_LAST_TRIGGER_TIME = now
  if math.random(1,100) <= GOD_CHANCE then
    local msg = EXERCISES[math.random(1,#EXERCISES)]
    if msg then outputExercise(msg) end
  end
end

-- Hook UseAction for GodBod
local _Orig_UseAction_God = UseAction
function UseAction(slot, checkCursor, onSelf)
  ensureLoaded()
  ensureGodLoaded()

  if WATCH_MODE then chat("pressed slot " .. tostring(slot)) end
  for _, cfg in pairs(WATCH_SLOTS) do if cfg.slot == slot then doBattleEmoteForSlot(cfg) end end

  if GOD_WATCH_MODE then godChat("pressed slot "..tostring(slot)) end
  if GOD_WATCH_SLOTS[slot] then triggerExercise() end

  return _Orig_UseAction_God(slot, checkCursor, onSelf)
end

-- /godbod slash commands
SLASH_GODBOD1 = "/godbod"
SlashCmdList["GODBOD"] = function(raw)
  ensureGodLoaded()
  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n and n >= 1 then
      GOD_WATCH_SLOTS[n] = true
      godChat("watching slot "..n.." (added).")
    else
      godChat("usage: /godbod slot <number>")
    end
    return
  end

  if cmd == "unslot" then
    local n = tonumber(rest)
    if n then GOD_WATCH_SLOTS[n] = nil; godChat("removed slot "..n) else godChat("usage: /godbod unslot <n>") end
    return
  end

  if cmd == "clear" then GOD_WATCH_SLOTS = {}; ensureGodDB().slots = {}; godChat("all slots cleared."); return end
  if cmd == "watch" then GOD_WATCH_MODE = not GOD_WATCH_MODE; godChat("watch mode "..(GOD_WATCH_MODE and "ON" or "OFF")); return end
  if cmd == "chance" then local n = tonumber(rest); if n and n>=0 and n<=100 then GOD_CHANCE=n; ensureGodDB().chance=n; godChat("trigger chance set to "..n.."%"); end; return end
  if cmd == "cd" then local n=tonumber(rest); if n and n>=0 then GOD_COOLDOWN=n; ensureGodDB().cooldown=n; godChat("cooldown set to "..n.."s"); end; return end
  if cmd == "on" then GOD_ENABLED=true; ensureGodDB().enabled=true; godChat("enabled."); return end
  if cmd == "off" then GOD_ENABLED=false; ensureGodDB().enabled=false; godChat("disabled."); return end
  if cmd == "info" then
    local count=0; for _ in pairs(GOD_WATCH_SLOTS) do count=count+1 end
    godChat("slots watched: "..count.." | chance: "..GOD_CHANCE.."% | cooldown: "..GOD_COOLDOWN.."s | enabled: "..tostring(GOD_ENABLED))
    return
  end

  godChat("/godbod slot <n> | unslot <n> | clear | watch | chance <0-100> | cd <s> | on | off | info")
end

-- Init / RNG / Save
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self,event)
  if event=="PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime()*1000)); math.random()
  elseif event=="PLAYER_LOGOUT" then
    local db = ensureDB()
    db.slots = WATCH_SLOTS
    db.enabled = ENABLED

    local goddb = ensureGodDB()
    goddb.slots = GOD_WATCH_SLOTS
    goddb.cooldown = GOD_COOLDOWN
    goddb.chance = GOD_CHANCE
    goddb.enabled = GOD_ENABLED
  end
end)
