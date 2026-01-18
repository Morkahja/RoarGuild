-- RoarGuild + GodBod Combined v1.0
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariables: ROGUDB, WorkThatGodBodDB

-------------------------------------------------
-- [BLOCK START] RoarGuild (ROGU) / Battle Emote 
-------------------------------------------------

local WATCH_SLOTS = {} -- [instance] = {slot, chance, cd, last, emoteIDs}
local WATCH_MODE = false
local ENABLED = true
local LAST_ROAR_TIME = 0
local LAST_REMINDER_TIME = 0
local ROAR_REMINDER_INTERVAL = 420
local ROAR_REMINDER_CD = 73
local LAST_GLOBAL_ROAR_TIME = 0
local GLOBAL_ROAR_CD = 2


local function roarChat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RoarGuild:|r "..text)
  end
end

local function roarNormalizeToken(token)
  token = token or ""
  token = string.gsub(token, "^%s+", "")
  token = string.gsub(token, "%s+$", "")
  token = string.upper(token)
  return token
end

local function roarEnsureEmoteDefaults(db)
  if type(db.emotes) ~= "table" then db.emotes = {} end
  if table.getn(db.emotes) < 1 then
    db.emotes[1] = { emote = "ROAR" }
  else
    if type(db.emotes[1]) ~= "table" or type(db.emotes[1].emote) ~= "string" or db.emotes[1].emote == "" then
      db.emotes[1] = { emote = "ROAR" }
    else
      db.emotes[1].emote = roarNormalizeToken(db.emotes[1].emote)
      if db.emotes[1].emote == "" then db.emotes[1].emote = "ROAR" end
    end
  end
end

local function roarEnsureDB()
  if type(ROGUDB) ~= "table" then ROGUDB = {} end
  if type(ROGUDB.slots) ~= "table" then ROGUDB.slots = {} end
  roarEnsureEmoteDefaults(ROGUDB)
  return ROGUDB
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

local function split_cmd(raw)
  local s = raw or ""
  s = string.gsub(s, "^%s+", "")
  local _, _, cmd, rest = string.find(s, "^(%S+)%s*(.*)$")
  if not cmd then cmd = "" rest = "" end
  return cmd, rest
end

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

local function roarArrayHas(t, value)
  if type(t) ~= "table" then return false end
  local i = 1
  while t[i] ~= nil do
    if t[i] == value then return true end
    i = i + 1
  end
  return false
end

local function roarFindEmoteID(db, token)
  token = roarNormalizeToken(token)
  if token == "" then return nil end
  local i = 1
  while db.emotes and db.emotes[i] do
    local e = db.emotes[i]
    if type(e) == "table" and type(e.emote) == "string" then
      if roarNormalizeToken(e.emote) == token then
        return i
      end
    end
    i = i + 1
  end
  return nil
end

local function roarSanitizeEmoteIDs(cfg, db)
  if type(cfg.emoteIDs) ~= "table" then cfg.emoteIDs = {} end

  local maxID = table.getn(db.emotes or {})
  if maxID < 1 then
    roarEnsureEmoteDefaults(db)
    maxID = table.getn(db.emotes)
  end

  local out = {}
  local seen = {}
  local i = 1
  while cfg.emoteIDs[i] ~= nil do
    local id = tonumber(cfg.emoteIDs[i])
    if id and id >= 1 and id <= maxID then
      if not seen[id] then
        out[table.getn(out) + 1] = id
        seen[id] = true
      end
    end
    i = i + 1
  end

  if table.getn(out) < 1 then
    out[1] = 1
  end

  cfg.emoteIDs = out
end

local function roarPickEmoteForCfg(cfg)
  local db = roarEnsureDB()
  local ids = (cfg and cfg.emoteIDs) or nil

  if type(ids) ~= "table" or table.getn(ids) < 1 then
    ids = { 1 }
  end

  local id = ids[math.random(1, table.getn(ids))]
  id = tonumber(id) or 1

  local entry = (db.emotes and db.emotes[id]) or nil
  local token = (entry and entry.emote) or "ROAR"
  token = roarNormalizeToken(token)
  if token == "" then token = "ROAR" end
  return token
end

local function doBattleEmoteForSlot(cfg)
  if not ENABLED or not cfg then return end

  local now = GetTime()
  cfg.last = cfg.last or 0

  if now - cfg.last < (cfg.cd or 0) then return end
  cfg.last = now

  if math.random(1,100) <= (cfg.chance or 0) then
    local token = roarPickEmoteForCfg(cfg)
    if token and token ~= "" then
      performEmote(token)
      LAST_ROAR_TIME = now
    end
  end
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

    if type(cfg.emoteIDs) ~= "table" or table.getn(cfg.emoteIDs) < 1 then
      cfg.emoteIDs = { 1 }
    end

    roarSanitizeEmoteIDs(cfg, db)
  end

  if db.enabled ~= nil then ENABLED = db.enabled end
  _roarLoaded = true
end

-------------------------------------------------
-- [BLOCK END] RoarGuild (ROGU) / Battle Emote
-------------------------------------------------


-------------------------------------------------
-- [BLOCK START] GodBod (exercise reminders)
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
  if roll >= 95 then
    SendChatMessage(text, "PARTY")
  elseif roll >= 93 then
    SendChatMessage(text, "YELL")
  elseif roll >= 91 then
    SendChatMessage(text, "SAY")
  elseif roll >= 87 then
    SendChatMessage(text, "GUILD")
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
-- [BLOCK END] GodBod (exercise reminders)
-------------------------------------------------


-------------------------------------------------
-- [BLOCK START] Hook UseAction (UPDATED: global fallback now DB-driven)
-------------------------------------------------

local _Orig_UseAction = UseAction

function UseAction(slot, checkCursor, onSelf)
  roarEnsureLoaded()
  godEnsureLoaded()

  local now = GetTime()

  if WATCH_MODE then
    roarChat("pressed slot "..tostring(slot))
  end

  for _, cfg in pairs(WATCH_SLOTS) do
    if cfg.slot == slot then
      doBattleEmoteForSlot(cfg)
    end
  end

  -- Global fallback: 0.5% chance on any action, uses instance 1's emoteIDs (or {1}).
  if ENABLED and slot and slot >= 1 and slot <= 200 then
    if math.random(1,1000) <= 5 then
      local cfg = WATCH_SLOTS[1]
      if not cfg then cfg = { emoteIDs = { 1 } } end
      local token = roarPickEmoteForCfg(cfg)
      if token and token ~= "" then
        performEmote(token)
        LAST_ROAR_TIME = now
      end
    end
  end


  if ENABLED and LAST_ROAR_TIME > 0 then
    if now - LAST_ROAR_TIME >= ROAR_REMINDER_INTERVAL
       and now - LAST_REMINDER_TIME >= ROAR_REMINDER_CD then
      roarChat("You have not roared in a while.")
      LAST_REMINDER_TIME = now
    end
  end

  if GOD_WATCH_MODE then
    godChat("pressed slot "..tostring(slot))
  end

  if GOD_WATCH_SLOTS[slot] then
    triggerExercise()
  end

  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- [BLOCK END] Hook UseAction (UPDATED: global fallback now DB-driven)
-------------------------------------------------


-------------------------------------------------
-- [BLOCK START] Slash Commands: /rogu (UPDATED)
-------------------------------------------------

SLASH_ROGU1 = "/rogu"
SlashCmdList["ROGU"] = function(raw)
  roarEnsureLoaded()
  local db = roarEnsureDB()
  local cmd, rest = split_cmd(raw)

  -- /rogu emote <TOKEN>
  -- /rogu emote list
  if cmd == "emote" then
    local sub = roarNormalizeToken(rest)

    if sub == "LIST" then
      local i = 1
      while db.emotes and db.emotes[i] do
        local token = (type(db.emotes[i]) == "table" and db.emotes[i].emote) or ""
        token = roarNormalizeToken(token)
        if token == "" then token = "?" end
        roarChat(tostring(i)..": "..token)
        i = i + 1
      end
      return
    end

    local token = roarNormalizeToken(rest)
    if token == "" then
      roarChat("usage: /rogu emote <TOKEN> | /rogu emote list")
      return
    end

    local existing = roarFindEmoteID(db, token)
    if existing then
      roarChat("emote exists: "..tostring(existing)..": "..token)
      return
    end

    local id = table.getn(db.emotes) + 1
    db.emotes[id] = { emote = token }
    roarChat("added emote "..tostring(id)..": "..token)

    for _, cfg in pairs(WATCH_SLOTS) do
      roarSanitizeEmoteIDs(cfg, db)
    end
    return
  end

  -- /rogu emoteX <id|-id|clear|list>
  local _, _, emoteIndex = string.find(cmd, "^emote(%d+)$")
  if emoteIndex then
    local instance = tonumber(emoteIndex)
    if not instance then
      roarChat("invalid instance")
      return
    end

    WATCH_SLOTS[instance] = WATCH_SLOTS[instance] or { slot=nil, chance=100, cd=6, last=0, emoteIDs={1} }
    local cfg = WATCH_SLOTS[instance]

    local arg = string.gsub(rest or "", "^%s+", "")
    arg = string.gsub(arg, "%s+$", "")

    if arg == "" then
      roarChat("usage: /rogu emote"..tostring(instance).." <id|-id|clear|list>")
      return
    end

    if string.lower(arg) == "clear" then
      cfg.emoteIDs = {1}
      roarChat("instance"..tostring(instance).." emotes set to: 1")
      return
    end

    if string.lower(arg) == "list" then
      roarSanitizeEmoteIDs(cfg, db)
      local out = ""
      local i = 1
      while cfg.emoteIDs[i] do
        local id = cfg.emoteIDs[i]
        local token = (db.emotes[id] and db.emotes[id].emote) or "ROAR"
        if out ~= "" then out = out.." | " end
        out = out..tostring(id)..":"..roarNormalizeToken(token)
        i = i + 1
      end
      roarChat("instance"..tostring(instance).." emotes: "..out)
      return
    end

    local remove = false
    if string.sub(arg,1,1) == "-" then
      remove = true
      arg = string.sub(arg,2)
      arg = string.gsub(arg, "^%s+", "")
    end

    local id = tonumber(arg)
    local maxID = table.getn(db.emotes)
    if not id or id < 1 or id > maxID then
      roarChat("invalid emote id (1-"..tostring(maxID)..")")
      return
    end

    roarSanitizeEmoteIDs(cfg, db)

    if remove then
      local new = {}
      for i=1,table.getn(cfg.emoteIDs) do
        if cfg.emoteIDs[i] ~= id then
          new[table.getn(new)+1] = cfg.emoteIDs[i]
        end
      end
      if table.getn(new) < 1 then new[1]=1 end
      cfg.emoteIDs = new
      roarChat("instance"..tostring(instance).." removed emote id "..tostring(id))
    else
      if roarArrayHas(cfg.emoteIDs, id) then
        roarChat("instance"..tostring(instance).." already has emote id "..tostring(id))
      else
        cfg.emoteIDs[table.getn(cfg.emoteIDs)+1] = id
        roarChat("instance"..tostring(instance).." added emote id "..tostring(id))
      end
    end
    return
  end

  -- existing commands
  local _, _, slotIndex = string.find(cmd, "^slot(%d+)$")
  if slotIndex then
    local instance = tonumber(slotIndex)
    local slot = tonumber(rest)
    if instance and slot then
      WATCH_SLOTS[instance] = WATCH_SLOTS[instance] or { emoteIDs={1} }
      WATCH_SLOTS[instance].slot = slot
      WATCH_SLOTS[instance].chance = WATCH_SLOTS[instance].chance or 100
      WATCH_SLOTS[instance].cd = WATCH_SLOTS[instance].cd or 6
      WATCH_SLOTS[instance].last = 0
      roarSanitizeEmoteIDs(WATCH_SLOTS[instance], db)
      roarChat("instance"..tostring(instance).." watching slot "..tostring(slot))
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
      roarChat("instance"..tostring(instance).." chance "..tostring(n).."%")
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
      roarChat("instance"..tostring(instance).." cooldown "..tostring(n).."s")
    else
      roarChat("invalid instance or value")
    end
    return
  end

  if cmd == "watch" then
    WATCH_MODE = not WATCH_MODE
    roarChat("watch mode "..(WATCH_MODE and "ON" or "OFF"))
    return
  end

  if cmd == "reset" then
    WATCH_SLOTS = {}
    roarEnsureDB().slots = WATCH_SLOTS
    roarChat("all instances cleared")
    return
  end

  if cmd == "info" then
    roarChat("enabled: "..tostring(ENABLED))
    roarChat("emotes in DB: "..tostring(table.getn(db.emotes)))
    for i,cfg in pairs(WATCH_SLOTS) do
      roarSanitizeEmoteIDs(cfg, db)
      local ids = ""
      for k=1,table.getn(cfg.emoteIDs or {}) do
        if ids ~= "" then ids = ids.."," end
        ids = ids..tostring(cfg.emoteIDs[k])
      end
      if ids == "" then ids = "1" end
      roarChat("instance"..tostring(i)..": slot "..tostring(cfg.slot).." | chance "..tostring(cfg.chance).."% | cd "..tostring(cfg.cd).."s | emotes ["..ids.."]")
    end
    return
  end

  if cmd == "on" then ENABLED=true; roarChat("enabled"); return end
  if cmd == "off" then ENABLED=false; roarChat("disabled"); return end
  if cmd == "rexp" then reportRestedXP(); return end

  if cmd == "roar" then
    local cfg = WATCH_SLOTS[1] or { emoteIDs={1} }
    performEmote(roarPickEmoteForCfg(cfg))
    LAST_ROAR_TIME = GetTime()
    return
  end

  roarChat("/rogu slotX <n> | chanceX <0-100> | timerX <sec> | emote <TOKEN> | emote list | emoteX <id|-id|clear|list> | watch | info | reset | on | off")
end

-------------------------------------------------
-- [BLOCK END] Slash Commands: /rogu (UPDATED)
-------------------------------------------------


-------------------------------------------------
-- [BLOCK START] Slash Commands: /godbod
-------------------------------------------------

SLASH_GODBOD1 = "/godbod"
SlashCmdList["GODBOD"] = function(raw)
  godEnsureLoaded()
  local cmd, rest = split_cmd(raw)

  if cmd == "slot" then
    local n = tonumber(rest)
    if n and n>=1 then
      GOD_WATCH_SLOTS[n] = true
      godChat("watching slot "..tostring(n))
    else
      godChat("usage: /godbod slot <n>")
    end
    return
  elseif cmd == "unslot" then
    local n = tonumber(rest)
    if n then
      GOD_WATCH_SLOTS[n] = nil
      godChat("removed slot "..tostring(n))
    else
      godChat("usage: /godbod unslot <n>")
    end
    return
  elseif cmd == "clear" then
    GOD_WATCH_SLOTS = {}
    godEnsureDB().slots = GOD_WATCH_SLOTS
    godChat("all slots cleared")
    return
  elseif cmd == "watch" then
    GOD_WATCH_MODE = not GOD_WATCH_MODE
    godChat("watch mode "..(GOD_WATCH_MODE and "ON" or "OFF"))
    return
  elseif cmd == "chance" then
    local n = tonumber(rest)
    if n and n>=0 and n<=100 then
      GOD_CHANCE = n
      godEnsureDB().chance = n
      godChat("trigger chance set to "..tostring(n).."%")
    end
    return
  elseif cmd == "cd" then
    local n = tonumber(rest)
    if n and n>=0 then
      GOD_COOLDOWN = n
      godEnsureDB().cooldown = n
      godChat("cooldown set to "..tostring(n).."s")
    end
    return
  elseif cmd == "on" then
    GOD_ENABLED = true
    godEnsureDB().enabled = true
    godChat("enabled.")
    return
  elseif cmd == "off" then
    GOD_ENABLED = false
    godEnsureDB().enabled = false
    godChat("disabled.")
    return
  elseif cmd == "info" then
    local count=0
    for _ in pairs(GOD_WATCH_SLOTS) do count=count+1 end
    godChat("slots watched: "..tostring(count).." | chance: "..tostring(GOD_CHANCE).."% | cooldown: "..tostring(GOD_COOLDOWN).."s | enabled: "..tostring(GOD_ENABLED))
    return
  end

  godChat("/godbod slot <n> | unslot <n> | clear | watch | chance <0-100> | cd <s> | on | off | info")
end

-------------------------------------------------
-- [BLOCK END] Slash Commands: /godbod
-------------------------------------------------


-------------------------------------------------
-- [BLOCK START] Init / Save (login + logout persistence)
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

-------------------------------------------------
-- [BLOCK END] Init / Save (login + logout persistence)
-------------------------------------------------
