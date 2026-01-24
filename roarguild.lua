-- RoarGuild v1.3
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariables: ROGUDB

-------------------------------------------------
-- [0] Constants
-------------------------------------------------
local ADDON_VERSION = "1.3"

local ROAR_REMINDER_INTERVAL = 420
local ROAR_REMINDER_CD = 73

local INVITE_CD = 20

-------------------------------------------------
-- [1] Shared Utils
-------------------------------------------------
local U = {}

function U.trim(s)
  s = s or ""
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  return s
end

function U.upper(s)
  return string.upper(U.trim(s or ""))
end

function U.split_cmd(raw)
  local s = U.trim(raw or "")
  local _, _, cmd, rest = string.find(s, "^(%S+)%s*(.*)$")
  if not cmd then return "", "" end
  return cmd, rest or ""
end

function U.pick(t)
  local n = table.getn(t or {})
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

function U.arrayHas(t, value)
  if type(t) ~= "table" then return false end
  local i = 1
  while t[i] ~= nil do
    if t[i] == value then return true end
    i = i + 1
  end
  return false
end

-------------------------------------------------
-- [2] RoarGuild (ROGU)
-------------------------------------------------
local ROGU = {
  slots = nil,          -- bound to ROGUDB.slots
  enabled = true,
  watchMode = false,

  lastRoar = 0,
  lastReminder = 0,
  lastInvite = 0,

  fallback = nil,       -- bound to ROGUDB.fallback (independent)
  _loaded = false,
}

-- Independent global fallback (separate from slot instances)
-- chancePermille: 5 => 0.5%
local FALLBACK_DEFAULT = { enabled=true, cd=2, chancePermille=5, last=0, emoteIDs={1} }

-- Invite text pool (used by /rogu invite)
local inviteText = {
  "<ROAR> A friendly guild for joy, curiosity, and shared adventures. We explore Azeroth together and roar at the good moments. You’re welcome to join us.",
  "<ROAR> Hear that? That’s Azeroth calling. We quest, wander, laugh, and /roar! Join us!",
  "<ROAR> A band of joyful explorers roaming Azeroth for stories, treasure, and good times. No rush, no pressure, just adventure and loud roars.",
  "<ROAR> The pride gathers! We celebrate level-ups, loot, sunsets, and silly moments with a good /roar. Casual adventures, big hearts. All welcome.",
  "<ROAR> Casual adventurers, loud celebrations, shared stories. If you like exploring and roaring, you belong here.",
  "<ROAR> A guild for joy, curiosity, and shared stories. Quest, dungeon, PvP, RP, collect, and wander together. Play to inspire, not to impress.",
  "<ROAR> Do you play for the world, not the meter? For stories, curiosity, and good vibes? We explore Azeroth together, join us!",
  "<ROAR> We play to inspire, not to impress. A home for curious souls, shared adventures, and good energy across Azeroth.",
  "<ROAR> Curious explorers and joyful wanderers wanted. We value respect, creativity, and shared stories. Let Azeroth hear your roar.",
  "<ROAR> Playing for curiosity, respect, and shared stories? So are we. Join us!",
  "<ROAR> Not in a hurry? Good. We wander, explore, and celebrate the journey with loud roars and good company.",
  "<ROAR> A casual guild for people who still enjoy getting lost in Azeroth. Stories, adventures, and plenty of /roar.",
  "<ROAR> We chase moments, not meters. Quests, dungeons, wandering, laughter, and roaring along the way.",
  "<ROAR> Join a pride that values curiosity, kindness, and shared adventures over rushing to the finish line.",
  "<ROAR> Azeroth is a world, not a checklist. Come explore it with us!",
  "<ROAR> From quiet wandering to loud celebrations, we enjoy every part of the journey together.",
  "<ROAR> A home for explorers, storytellers, collectors, fighters, and friendly souls. We also roar a lot.",
  "<ROAR> If you enjoy playing at your own pace and sharing the adventure, ROAR might be your new home.",
  "<ROAR> We celebrate the small wins, the big moments, and everything in between. Join us and roar along.",
  "<ROAR> Adventure feels better when shared. Explore Azeroth with us and let your voice be heard."
}

local function roarChat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RoarGuild:|r "..tostring(text or ""))
  end
end

local function performEmote(token)
  if DoEmote then
    DoEmote(token)
  else
    SendChatMessage("makes a battle cry!", "EMOTE")
  end
end

-- DB defaults
local function ROGU_EnsureEmoteDefaults(db)
  if type(db.emotes) ~= "table" then db.emotes = {} end
  if table.getn(db.emotes) < 1 then
    db.emotes[1] = { emote = "ROAR" }
  else
    if type(db.emotes[1]) ~= "table" or type(db.emotes[1].emote) ~= "string" or db.emotes[1].emote == "" then
      db.emotes[1] = { emote = "ROAR" }
    else
      db.emotes[1].emote = U.upper(db.emotes[1].emote)
      if db.emotes[1].emote == "" then db.emotes[1].emote = "ROAR" end
    end
  end
end

local function ROGU_EnsureFallbackDefaults(db)
  if type(db.fallback) ~= "table" then db.fallback = {} end
  local fb = db.fallback

  if fb.enabled == nil then fb.enabled = FALLBACK_DEFAULT.enabled end
  if fb.cd == nil then fb.cd = FALLBACK_DEFAULT.cd end
  if fb.chancePermille == nil then fb.chancePermille = FALLBACK_DEFAULT.chancePermille end
  if fb.last == nil then fb.last = 0 end
  if type(fb.emoteIDs) ~= "table" or table.getn(fb.emoteIDs) < 1 then
    fb.emoteIDs = { 1 }
  end
end

local function ROGU_EnsureDB()
  if type(ROGUDB) ~= "table" then ROGUDB = {} end
  if type(ROGUDB.slots) ~= "table" then ROGUDB.slots = {} end
  ROGU_EnsureEmoteDefaults(ROGUDB)
  ROGU_EnsureFallbackDefaults(ROGUDB)
  return ROGUDB
end

local function ROGU_FindEmoteID(db, token)
  token = U.upper(token)
  if token == "" then return nil end
  local i = 1
  while db.emotes and db.emotes[i] do
    local e = db.emotes[i]
    if type(e) == "table" and type(e.emote) == "string" then
      if U.upper(e.emote) == token then
        return i
      end
    end
    i = i + 1
  end
  return nil
end

-- Sanitizes cfg.emoteIDs: keeps only unique numeric ids within [1..#db.emotes], ensures at least {1}.
local function ROGU_SanitizeEmoteIDs(cfg, db)
  if type(cfg.emoteIDs) ~= "table" then cfg.emoteIDs = {} end

  local maxID = table.getn(db.emotes or {})
  if maxID < 1 then
    ROGU_EnsureEmoteDefaults(db)
    maxID = table.getn(db.emotes)
  end

  local out, seen = {}, {}
  local i = 1
  while cfg.emoteIDs[i] ~= nil do
    local id = tonumber(cfg.emoteIDs[i])
    if id and id >= 1 and id <= maxID and not seen[id] then
      out[table.getn(out) + 1] = id
      seen[id] = true
    end
    i = i + 1
  end

  if table.getn(out) < 1 then out[1] = 1 end
  cfg.emoteIDs = out
end

-- Picks a random emote token using cfg.emoteIDs -> db.emotes[id].emote, fallback ROAR.
local function ROGU_PickEmoteForCfg(cfg)
  local db = ROGU_EnsureDB()
  local ids = (cfg and cfg.emoteIDs) or nil

  if type(ids) ~= "table" or table.getn(ids) < 1 then
    ids = { 1 }
  end

  local id = ids[math.random(1, table.getn(ids))]
  id = tonumber(id) or 1

  local entry = (db.emotes and db.emotes[id]) or nil
  local token = (entry and entry.emote) or "ROAR"
  token = U.upper(token)
  if token == "" then token = "ROAR" end
  return token
end

-- One-time loader: bind runtime vars to DB tables, fill defaults, sanitize emoteIDs.
local function ROGU_LoadOnce()
  if ROGU._loaded then return end
  local db = ROGU_EnsureDB()

  ROGU.slots = db.slots
  ROGU.fallback = db.fallback

  if db.enabled ~= nil then ROGU.enabled = db.enabled end

  for _, cfg in pairs(ROGU.slots) do
    if cfg.chance == nil then cfg.chance = 100 end
    if cfg.cd == nil then cfg.cd = 6 end
    if cfg.last == nil then cfg.last = 0 end
    if type(cfg.emoteIDs) ~= "table" or table.getn(cfg.emoteIDs) < 1 then
      cfg.emoteIDs = { 1 }
    end
    ROGU_SanitizeEmoteIDs(cfg, db)
  end

  ROGU_SanitizeEmoteIDs(ROGU.fallback, db)

  ROGU._loaded = true
end

-- Invite: ONLY channel 1
local function ROGU_SendInvite()
  local now = GetTime()
  if (now - (ROGU.lastInvite or 0)) < INVITE_CD then
    local wait = math.ceil(INVITE_CD - (now - ROGU.lastInvite))
    roarChat("invite cooldown: "..tostring(wait).."s")
    return
  end
  ROGU.lastInvite = now

  local msg = U.pick(inviteText)
  if not msg or msg == "" then return end

  SendChatMessage(msg, "CHANNEL", nil, 1)
end

local function ROGU_DoBattleEmoteForCfg(cfg, now)
  if not ROGU.enabled or not cfg then return end

  cfg.last = cfg.last or 0
  if now - cfg.last < (cfg.cd or 0) then return end
  cfg.last = now

  if math.random(1,100) <= (cfg.chance or 0) then
    local token = ROGU_PickEmoteForCfg(cfg)
    if token and token ~= "" then
      performEmote(token)
      ROGU.lastRoar = now
    end
  end
end

-- Independent fallback: does NOT depend on slot instances; uses its own cooldown/last/chance
local function ROGU_TryFallback(now, slot)
  if not ROGU.enabled then return end
  local fb = ROGU.fallback
  if type(fb) ~= "table" then return end
  if fb.enabled == false then return end

  if not slot or slot < 1 or slot > 200 then return end

  fb.last = fb.last or 0
  if now - fb.last < (fb.cd or 0) then return end

  local perm = tonumber(fb.chancePermille) or 0
  if perm < 0 then perm = 0 end
  if perm > 1000 then perm = 1000 end

  if math.random(1,1000) <= perm then
    local token = ROGU_PickEmoteForCfg(fb)
    if token and token ~= "" then
      performEmote(token)
      ROGU.lastRoar = now
      fb.last = now
    end
  end
end

local function ROGU_MaybeReminder(now)
  if not ROGU.enabled then return end
  if ROGU.lastRoar > 0 then
    if now - ROGU.lastRoar >= ROAR_REMINDER_INTERVAL
       and now - (ROGU.lastReminder or 0) >= ROAR_REMINDER_CD then
      roarChat("You have not roared in a while.")
      ROGU.lastReminder = now
    end
  end
end

local function ROGU_ReportRestedXP()
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

-------------------------------------------------
-- [3] Hook UseAction (single owner)
-------------------------------------------------
local _Orig_UseAction = UseAction

function UseAction(slot, checkCursor, onSelf)
  ROGU_LoadOnce()

  local now = GetTime()

  if ROGU.watchMode then
    roarChat("pressed slot "..tostring(slot))
  end

  -- Roar slot instances
  for _, cfg in pairs(ROGU.slots) do
    if cfg.slot == slot then
      ROGU_DoBattleEmoteForCfg(cfg, now)
    end
  end

  -- Independent fallback (always active; independent of instances)
  ROGU_TryFallback(now, slot)

  -- Reminder
  ROGU_MaybeReminder(now)

  return _Orig_UseAction(slot, checkCursor, onSelf)
end

-------------------------------------------------
-- [4] Slash Commands: /rogu
-------------------------------------------------
SLASH_ROGU1 = "/rogu"
SlashCmdList["ROGU"] = function(raw)
  ROGU_LoadOnce()
  local db = ROGU_EnsureDB()
  local cmd, rest = U.split_cmd(raw)
  cmd = U.upper(cmd)

  -- /rogu invite
  if cmd == "INVITE" then
    ROGU_SendInvite()
    return
  end

  -- /rogu emote <TOKEN>
  -- /rogu emote list
  if cmd == "EMOTE" then
    local sub = U.upper(rest)

    if sub == "LIST" then
      local i = 1
      while db.emotes and db.emotes[i] do
        local token = (type(db.emotes[i]) == "table" and db.emotes[i].emote) or ""
        token = U.upper(token)
        if token == "" then token = "?" end
        roarChat(tostring(i)..": "..token)
        i = i + 1
      end
      return
    end

    local token = U.upper(rest)
    if token == "" then
      roarChat("usage: /rogu emote <TOKEN> | /rogu emote list")
      return
    end

    local existing = ROGU_FindEmoteID(db, token)
    if existing then
      roarChat("emote exists: "..tostring(existing)..": "..token)
      return
    end

    local id = table.getn(db.emotes) + 1
    db.emotes[id] = { emote = token }
    roarChat("added emote "..tostring(id)..": "..token)

    for _, cfg in pairs(ROGU.slots) do
      ROGU_SanitizeEmoteIDs(cfg, db)
    end
    ROGU_SanitizeEmoteIDs(ROGU.fallback, db)
    return
  end

  -- /rogu emoteX <id|-id|clear|list>
  local _, _, emoteIndex = string.find(cmd, "^EMOTE(%d+)$")
  if emoteIndex then
    local instance = tonumber(emoteIndex)
    if not instance then
      roarChat("invalid instance")
      return
    end

    ROGU.slots[instance] = ROGU.slots[instance] or { slot=nil, chance=100, cd=6, last=0, emoteIDs={1} }
    local cfg = ROGU.slots[instance]

    local arg = U.trim(rest or "")
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
      ROGU_SanitizeEmoteIDs(cfg, db)
      local out = ""
      local i = 1
      while cfg.emoteIDs[i] do
        local id = cfg.emoteIDs[i]
        local token = (db.emotes[id] and db.emotes[id].emote) or "ROAR"
        if out ~= "" then out = out.." | " end
        out = out..tostring(id)..":"..U.upper(token)
        i = i + 1
      end
      roarChat("instance"..tostring(instance).." emotes: "..out)
      return
    end

    local remove = false
    if string.sub(arg, 1, 1) == "-" then
      remove = true
      arg = U.trim(string.sub(arg, 2))
    end

    local id = tonumber(arg)
    local maxID = table.getn(db.emotes)
    if not id or id < 1 or id > maxID then
      roarChat("invalid emote id (1-"..tostring(maxID)..")")
      return
    end

    ROGU_SanitizeEmoteIDs(cfg, db)

    if remove then
      local new = {}
      for i=1,table.getn(cfg.emoteIDs) do
        if cfg.emoteIDs[i] ~= id then
          new[table.getn(new)+1] = cfg.emoteIDs[i]
        end
      end
      if table.getn(new) < 1 then new[1] = 1 end
      cfg.emoteIDs = new
      roarChat("instance"..tostring(instance).." removed emote id "..tostring(id))
    else
      if U.arrayHas(cfg.emoteIDs, id) then
        roarChat("instance"..tostring(instance).." already has emote id "..tostring(id))
      else
        cfg.emoteIDs[table.getn(cfg.emoteIDs)+1] = id
        roarChat("instance"..tostring(instance).." added emote id "..tostring(id))
      end
    end
    return
  end

  -- /rogu slotX <slot>
  local _, _, slotIndex = string.find(cmd, "^SLOT(%d+)$")
  if slotIndex then
    local instance = tonumber(slotIndex)
    local slot = tonumber(rest)
    if instance and slot then
      ROGU.slots[instance] = ROGU.slots[instance] or { emoteIDs={1} }
      ROGU.slots[instance].slot = slot
      ROGU.slots[instance].chance = ROGU.slots[instance].chance or 100
      ROGU.slots[instance].cd = ROGU.slots[instance].cd or 6
      ROGU.slots[instance].last = 0
      ROGU_SanitizeEmoteIDs(ROGU.slots[instance], db)
      roarChat("instance"..tostring(instance).." watching slot "..tostring(slot))
    else
      roarChat("usage: /rogu slotX <slot>")
    end
    return
  end

  -- /rogu chanceX <0-100>
  local _, _, chanceIndex = string.find(cmd, "^CHANCE(%d+)$")
  if chanceIndex then
    local instance = tonumber(chanceIndex)
    local n = tonumber(rest)
    if ROGU.slots[instance] and n and n>=0 and n<=100 then
      ROGU.slots[instance].chance = n
      roarChat("instance"..tostring(instance).." chance "..tostring(n).."%")
    else
      roarChat("invalid instance or value")
    end
    return
  end

  -- /rogu timerX <sec>
  local _, _, timerIndex = string.find(cmd, "^TIMER(%d+)$")
  if timerIndex then
    local instance = tonumber(timerIndex)
    local n = tonumber(rest)
    if ROGU.slots[instance] and n and n>=0 then
      ROGU.slots[instance].cd = n
      roarChat("instance"..tostring(instance).." cooldown "..tostring(n).."s")
    else
      roarChat("invalid instance or value")
    end
    return
  end

  if cmd == "WATCH" then
    ROGU.watchMode = not ROGU.watchMode
    roarChat("watch mode "..(ROGU.watchMode and "ON" or "OFF"))
    return
  end

  if cmd == "RESET" then
    ROGU.slots = {}
    ROGU_EnsureDB().slots = ROGU.slots
    roarChat("all instances cleared")
    return
  end

  if cmd == "INFO" then
    roarChat("enabled: "..tostring(ROGU.enabled))
    roarChat("emotes in DB: "..tostring(table.getn(db.emotes)))

    if type(ROGU.fallback) == "table" then
      local fb = ROGU.fallback
      ROGU_SanitizeEmoteIDs(fb, db)
      local fbids = ""
      local k=1
      while fb.emoteIDs and fb.emoteIDs[k] do
        if fbids ~= "" then fbids = fbids.."," end
        fbids = fbids..tostring(fb.emoteIDs[k])
        k = k + 1
      end
      if fbids == "" then fbids = "1" end
      roarChat("fallback: enabled "..tostring(fb.enabled).." | cd "..tostring(fb.cd).."s | chance "..tostring(fb.chancePermille).."/1000 | emotes ["..fbids.."]")
    end

    for i,cfg in pairs(ROGU.slots) do
      ROGU_SanitizeEmoteIDs(cfg, db)
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

  if cmd == "ON" then ROGU.enabled=true; db.enabled=true; roarChat("enabled"); return end
  if cmd == "OFF" then ROGU.enabled=false; db.enabled=false; roarChat("disabled"); return end
  if cmd == "REXP" then ROGU_ReportRestedXP(); return end

  if cmd == "ROAR" then
    local token = ROGU_PickEmoteForCfg(ROGU.slots[1] or { emoteIDs={1} })
    performEmote(token)
    ROGU.lastRoar = GetTime()
    return
  end

  roarChat(" invite | slotX <n> | chanceX <0-100> | timerX <sec> | emote <TOKEN> | emote list | emoteX <id|-id|clear|list> | watch | info | reset | on | off | rexp | roar")
end

-------------------------------------------------
-- [5] Init / Save (login + logout persistence)
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime() * 1000))
    math.random()
  elseif event == "PLAYER_LOGOUT" then
    local db = ROGU_EnsureDB()
    db.slots = ROGU.slots
    db.enabled = ROGU.enabled
    db.fallback = ROGU.fallback
  end
end)
