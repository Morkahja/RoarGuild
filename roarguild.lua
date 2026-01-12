-- RoarGuild + GodBod Combined v1.0
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariables: ROGUDB, WorkThatGodBodDB

-------------------------------------------------
-- ROGU / Battle Emote
-------------------------------------------------
local EMOTE_TOKENS_BATTLE = { "ROAR","CHEER","FLEX" }

local WATCH_SLOTS = {} -- [instance] = {slot, chance, cd, last}
local WATCH_MODE = false
local ENABLED = true

local function roarChat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RoarGuild:|r "..text)
  end
end

local function roarEnsureDB()
  if type(ROGUDB) ~= "table" then ROGUDB = {} end
  if type(ROGUDB.slots) ~= "table" then ROGUDB.slots = {} end
  return ROGUDB
end

local _roarLoaded = false
local function roarEnsureLoaded()
  if _roarLoaded then return end
  local db = roarEnsureDB()
  WATCH_SLOTS = db.slots
  for _, cfg in pairs(WATCH_SLOTS) do
    if cfg.chance == nil then cfg.chance = 100 end
    if cfg.cd == nil then cfg.cd = 6 end
    if cfg.last == nil then cfg.last = 0 end
  end
  if db.enabled ~= nil then ENABLED = db.enabled end
  _roarLoaded = true
end

local function pick(t)
  local n = table.getn(t)
  if n < 1 then return nil end
  return t[math.random(1,n)]
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

-------------------------------------------------
-- GodBod
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
  "Move with intention for one full minute.",
  "Slowly tilt your head ear to shoulder. Switch sides.",
"Clench fists for five seconds. Release fully.",
"Press your feet into the floor. Feel the ground.",
"Slide your shoulders up, back, then down.",
"Straighten one leg. Flex the foot. Switch.",
"Tap your toes rapidly for twenty seconds.",
"Gently massage your temples in small circles.",
"Interlace fingers. Push palms forward. Stretch upper back.",
"Draw slow circles with your nose.",
"Stand and stretch one arm across the chest. Switch.",
"Lift shoulders to ears. Hold three seconds. Drop.",
"Rotate your torso slowly while seated.",
"Extend arms out. Make small pulses backward.",
"Open your mouth wide. Close gently. Repeat.",
"Seated hamstring stretch. One leg at a time.",
"Press palms into desk. Straighten arms. Chest stretch.",
"Slow ankle circles in both directions.",
"March slowly, lifting knees high.",
"Rest eyes. Cover them with palms for ten seconds.",
"Engage core lightly while breathing normally.",
"Seated cat-cow spinal movement.",
"Lift heels, then toes, alternating.",
"Draw figure eights with your shoulders.",
"Stretch one side of neck diagonally. Switch.",
"Stand and gently sway side to side.",
"Extend arms overhead. Interlace fingers. Reach up.",
"Slowly open chest while inhaling.",
"Tap fingers to thumb, one by one.",
"Straighten spine. Lengthen, don’t stiffen.",
"Press knees outward gently while seated.",
"Shake out forearms from elbows down.",
"Do ten slow seated calf pumps.",
"Clasp hands behind head. Elbows wide.",
"Deep belly breath for five counts.",
"Stretch one quad by bending knee back. Switch.",
"Roll feet over imaginary pebbles.",
"Lift arms to shoulder height. Hold briefly.",
"Turn head diagonally left and right.",
"Lightly bounce on the balls of your feet.",
"Seated side bend. Switch sides.",
"Relax shoulders away from ears.",
"Press palms together firmly for five seconds.",
"Extend one arm up, one down. Switch.",
"Slow controlled sit-back squat.",
"Rotate ribcage gently without moving hips.",
"Stand tall and breathe into your back.",
"Open hands like releasing energy.",
"Reset spine from pelvis upward.",
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
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000GodBod:|r "..text)
  end
end

local function outputExercise(text)
  local roll = math.random(1,100)
  if roll >= 99 then
    SendChatMessage(text,"CHANNEL",nil,6)
  elseif roll >= 97 then
    SendChatMessage(text,"CHANNEL",nil,1)
  elseif roll >= 95 then
    SendChatMessage(text,"PARTY")
  elseif roll >= 93 then
    SendChatMessage(text,"YELL")
  elseif roll >= 91 then
    SendChatMessage(text,"SAY")
  else
    godChat(text)
  end
end

local function godEnsureDB()
  if type(WorkThatGodBodDB) ~= "table" then WorkThatGodBodDB = {} end
  if type(WorkThatGodBodDB.slots) ~= "table" then WorkThatGodBodDB.slots = {} end
  return WorkThatGodBodDB
end

local _godLoaded = false
local function godEnsureLoaded()
  if _godLoaded then return end
  local db = godEnsureDB()
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
    local msg = pick(EXERCISES)
    if msg then outputExercise(msg) end
  end
end

-------------------------------------------------
-- Hook UseAction (with global 0.5% RoarGuild chance)
-------------------------------------------------
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
  roarEnsureLoaded()
  godEnsureLoaded()

  local matched = false

  if WATCH_MODE then roarChat("pressed slot "..tostring(slot)) end
  for _, cfg in pairs(WATCH_SLOTS) do
    if cfg.slot == slot then
      matched = true
      doBattleEmoteForSlot(cfg)
    end
  end

  -- Global fallback: 0.5% chance on any action slot
  if ENABLED and not matched and slot and slot >= 1 and slot <= 200 then
    if math.random(1,1000) <= 5 then
      local e = pick(EMOTE_TOKENS_BATTLE)
      if e then performEmote(e) end
    end
  end

  if GOD_WATCH_MODE then godChat("pressed slot "..tostring(slot)) end
  if GOD_WATCH_SLOTS[slot] then triggerExercise() end

  return _Orig_UseAction(slot, checkCursor, onSelf)
end


-------------------------------------------------
-- Slash Commands /rogu
-------------------------------------------------
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

  local _, _, chanceIndex = string.find(cmd, "^chance(%d+)$")
  if chanceIndex then
    local instance = tonumber(chanceIndex)
    local n = tonumber(rest)
    if WATCH_SLOTS[instance] and n and n>=0 and n<=100 then
      WATCH_SLOTS[instance].chance = n
      roarChat("instance"..instance.." chance "..n.."%")
    else
      roarChat("invalid instance or value")
    end
    return
  end

  local _, _, timerIndex = string.find(cmd, "^timer(%d+)$")
  if timerIndex then
    local instance = tonumber(timerIndex)
    local n = tonumber(rest)
    if WATCH_SLOTS[instance] and n and n>=0 then
      WATCH_SLOTS[instance].cd = n
      roarChat("instance"..instance.." cooldown "..n.."s")
    else
      roarChat("invalid instance or value")
    end
    return
  end

  if cmd == "watch" then WATCH_MODE = not WATCH_MODE; roarChat("watch mode "..(WATCH_MODE and "ON" or "OFF")); return end
  if cmd == "reset" then WATCH_SLOTS = {}; roarEnsureDB().slots = WATCH_SLOTS; roarChat("all instances cleared"); return end
  if cmd == "info" then
    roarChat("enabled: "..tostring(ENABLED))
    for i,cfg in pairs(WATCH_SLOTS) do
      roarChat("instance"..i..": slot "..cfg.slot.." | chance "..cfg.chance.."% | cd "..cfg.cd.."s")
    end
    return
  end
  if cmd == "on" then ENABLED = true roarChat("enabled"); return end
  if cmd == "off" then ENABLED = false roarChat("disabled"); return end
  if cmd == "rexp" then
    
-- RESTED XP
  local function reportRestedXP()
    local r = GetXPExhaustion()
    if not r then
      roarChat("No rest.")
      return
    end
    local m = UnitXPMax("player")
    if not m or m == 0 then
      roarChat("No XP data.")
      return
    end
    local bubbles = math.floor((r * 20) / m + 0.5)
    if bubbles > 30 then bubbles = 30 end
    roarChat("Rest: "..bubbles.." bubbles ("..r.." XP)")
  end
  reportRestedXP()
  return
end

  roarChat("/rogu slotX <n> | chanceX <0-100> | timerX <sec> | watch | info | reset | on | off")
end


-------------------------------------------------
-- Slash Commands /godbod
-------------------------------------------------
SLASH_GODBOD1 = "/godbod"
SlashCmdList["GODBOD"] = function(raw)
  godEnsureLoaded()
  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n and n>=1 then GOD_WATCH_SLOTS[n] = true; godChat("watching slot "..n) else godChat("usage: /godbod slot <n>") end
    return
  elseif cmd == "unslot" then
    local n = tonumber(rest)
    if n then GOD_WATCH_SLOTS[n] = nil; godChat("removed slot "..n) else godChat("usage: /godbod unslot <n>") end
    return
  elseif cmd == "clear" then GOD_WATCH_SLOTS = {}; godEnsureDB().slots = GOD_WATCH_SLOTS; godChat("all slots cleared"); return
  elseif cmd == "watch" then GOD_WATCH_MODE = not GOD_WATCH_MODE; godChat("watch mode "..(GOD_WATCH_MODE and "ON" or "OFF")); return
  elseif cmd == "chance" then local n=tonumber(rest); if n and n>=0 and n<=100 then GOD_CHANCE=n; godEnsureDB().chance=n; godChat("trigger chance set to "..n.."%"); end; return
  elseif cmd == "cd" then local n=tonumber(rest); if n and n>=0 then GOD_COOLDOWN=n; godEnsureDB().cooldown=n; godChat("cooldown set to "..n.."s"); end; return
  elseif cmd == "on" then GOD_ENABLED=true; godEnsureDB().enabled=true; godChat("enabled."); return
  elseif cmd == "off" then GOD_ENABLED=false; godEnsureDB().enabled=false; godChat("disabled."); return
  elseif cmd == "info" then
    local count=0; for _ in pairs(GOD_WATCH_SLOTS) do count=count+1 end
    godChat("slots watched: "..count.." | chance: "..GOD_CHANCE.."% | cooldown: "..GOD_COOLDOWN.."s | enabled: "..tostring(GOD_ENABLED))
    return
  end

  godChat("/godbod slot <n> | unslot <n> | clear | watch | chance <0-100> | cd <s> | on | off | info")
end

-------------------------------------------------
-- Init / Save
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event)
  if event=="PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime()*1000))
    math.random()
  elseif event=="PLAYER_LOGOUT" then
    local db = roarEnsureDB()
    db.slots = WATCH_SLOTS
    db.enabled = ENABLED

    local goddb = godEnsureDB()
    goddb.slots = GOD_WATCH_SLOTS
    goddb.cooldown = GOD_COOLDOWN
    goddb.chance = GOD_CHANCE
    goddb.enabled = GOD_ENABLED
  end
end)
