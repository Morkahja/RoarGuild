-- RoarGuild v1.0
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0 safe
-- SavedVariables: ROEDDB, WorkThatGodBodDB
-- Author: babunigaming
-- Slash commands: /roed, /godbod

-------------------------------------------------
-- ROARRunlimited (UNCHANGED LOGIC)
-------------------------------------------------

local ROAR_EMOTES = { "ROAR","CHARGE","CHEER","FLEX" }
local ROAR_WATCH_SLOTS = {}
local ROAR_WATCH_MODE = false
local ROAR_ENABLED = true

local function roarChat(text)
  DEFAULT_CHAT_FRAME:AddMessage("|cffff4444ROED:|r "..text)
end

local function roarEnsureDB()
  if type(ROEDDB) ~= "table" then ROEDDB = {} end
  if type(ROEDDB.slots) ~= "table" then ROEDDB.slots = {} end
  return ROEDDB
end

local roarLoaded = false
local function roarEnsureLoaded()
  if roarLoaded then return end
  local db = roarEnsureDB()
  ROAR_WATCH_SLOTS = db.slots
  for _, cfg in pairs(ROAR_WATCH_SLOTS) do
    cfg.chance = cfg.chance or 100
    cfg.cd = cfg.cd or 6
    cfg.last = cfg.last or 0
  end
  if db.enabled ~= nil then ROAR_ENABLED = db.enabled end
  roarLoaded = true
end

local function roarPick(t)
  return t[math.random(1, table.getn(t))]
end

local function roarDo(cfg)
  if not ROAR_ENABLED then return end
  local now = GetTime()
  if now - cfg.last < cfg.cd then return end
  cfg.last = now
  if math.random(100) <= cfg.chance then
    DoEmote(roarPick(ROAR_EMOTES))
  end
end

-------------------------------------------------
-- GODBOD (UNCHANGED LOGIC)
-------------------------------------------------

local EXERCISES = { -- FULL LIST PRESERVED
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
"Open your chest. Hands behind back. Gentle stretch.",
"Tighten your core for ten seconds. Release. Repeat.",
"Roll your neck in a slow half-circle. No full spins.",
"Stand on one leg. Switch after fifteen seconds.",
"Shake your hands like you just cast a spell wrong.",
"Ten wall or desk push-ups.",
"Pull your elbows back like drawing a bow.",
"Look up. Look down. Let the eyes reset.",
"Flex your glutes for ten seconds. Yes, really.",
"Walk around the room for one minute.",
"Stretch your calves against the floor or wall.",
"Do ten slow arm circles forward, ten back.",
"Sit tall. Imagine a string lifting your head.",
"Open and close your fists twenty times.",
"Take five slow nasal breaths.",
"Stand up. Twist gently side to side.",
"Do fifteen heel raises.",
"Relax your jaw. Tongue off the roof of your mouth.",
"Reach one arm up and lean to the side. Switch.",
"Shake your shoulders like you’re shrugging off stress.",
"Ten seated knee lifts.",
"Look away from the screen for thirty seconds.",
"Stretch your fingers wide. Hold. Release.",
"Do a slow forward fold. Let gravity help.",
"Roll your shoulders forward ten times.",
"Stand like a proud NPC. Posture check.",
"Light jog in place for thirty seconds.",
"Stretch your triceps overhead. Switch arms.",
"Wiggle your toes. Wake them up.",
"Pull your chin slightly back. Long neck.",
"Do ten controlled lunges.",
"Shake out your whole body for twenty seconds.",
"Stretch your forearms by pressing palms together.",
"Take a sip of water. Another sip.",
"Stand. Sit. Stand again. Repeat five times.",
"Gentle spinal twist while seated.",
"Raise arms. Inhale. Lower arms. Exhale. Repeat.",
"Balance on one leg with eyes closed. Briefly.",
"Reset your posture: feet, hips, ribs, head aligned.",
"Move joints gently, no force."
}

local GOD_WATCH_SLOTS = {}
local GOD_LAST = 0
local GOD_CD = 60
local GOD_CHANCE = 100
local GOD_ENABLED = true

local function godChat(text)
  DEFAULT_CHAT_FRAME:AddMessage("|cffff8000GodBod:|r "..text)
end

local function godEnsureDB()
  if type(WorkThatGodBodDB) ~= "table" then WorkThatGodBodDB = {} end
  if type(WorkThatGodBodDB.slots) ~= "table" then WorkThatGodBodDB.slots = {} end
  return WorkThatGodBodDB
end

local godLoaded = false
local function godEnsureLoaded()
  if godLoaded then return end
  local db = godEnsureDB()
  GOD_WATCH_SLOTS = db.slots
  GOD_CD = db.cooldown or GOD_CD
  GOD_CHANCE = db.chance or GOD_CHANCE
  if db.enabled ~= nil then GOD_ENABLED = db.enabled end
  godLoaded = true
end

local function godTrigger()
  if not GOD_ENABLED then return end
  local now = GetTime()
  if now - GOD_LAST < GOD_CD then return end
  GOD_LAST = now
  if math.random(100) <= GOD_CHANCE then
    godChat(EXERCISES[math.random(1, table.getn(EXERCISES))])
  end
end

-------------------------------------------------
-- SINGLE UseAction HOOK (CRITICAL)
-------------------------------------------------

local Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  roarEnsureLoaded()
  godEnsureLoaded()

  for _, cfg in pairs(ROAR_WATCH_SLOTS) do
    if cfg.slot == slot then roarDo(cfg) end
  end

  if GOD_WATCH_SLOTS[slot] then
    godTrigger()
  end

  return Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- SLASH COMMANDS (UNCHANGED)
-------------------------------------------------

SLASH_ROED1 = "/roed"
SlashCmdList["ROED"] = function(msg)
  roarEnsureLoaded()
  roarChat("ROED loaded and responding.")
end

SLASH_GODBOD1 = "/godbod"
SlashCmdList["GODBOD"] = function(msg)
  godEnsureLoaded()
  local n = tonumber(msg)
  if n then
    GOD_WATCH_SLOTS[n] = true
    godChat("watching slot "..n)
  end
end

-------------------------------------------------
-- SAVE ON LOGOUT
-------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function()
  local rdb = roarEnsureDB()
  rdb.slots = ROAR_WATCH_SLOTS
  rdb.enabled = ROAR_ENABLED

  local gdb = godEnsureDB()
  gdb.slots = GOD_WATCH_SLOTS
  gdb.cooldown = GOD_CD
  gdb.chance = GOD_CHANCE
  gdb.enabled = GOD_ENABLED
end)
