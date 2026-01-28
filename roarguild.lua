-- RoarGuild v1.3 (GodBod removed, Option C profiles)
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariables: ROGUDB

-------------------------------------------------
-- [0] Constants
-------------------------------------------------
local ADDON_VERSION = "1.3"

local ROAR_REMINDER_INTERVAL = 420
local ROAR_REMINDER_CD = 73

-- Independent global fallback defaults (per-profile)
-- chancePermille: 5 => 0.5%
local FALLBACK_DEFAULT = { enabled=true, cd=2, chancePermille=5, last=0, emoteIDs={1} }

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
-- [2] RoarGuild (ROGU) State
-------------------------------------------------
local ROGU = {
  profileKey = nil,
  profile = nil,        -- bound to ROGUDB.profiles[key]
  slots = nil,          -- bound to profile.slots
  fallback = nil,       -- bound to profile.fallback
  enabled = true,       -- from profile.enabled
  watchMode = false,

  lastRoar = 0,
  lastReminder = 0,

  _loaded = false,
}

-------------------------------------------------
-- [2.1] Data Pools
-------------------------------------------------
local inviteText = {
  "<ROAR> Is a friendly guild for joy, curiosity, and shared adventures. We explore Azeroth at our own pace and roar alot. You’re welcome to join us.",
  "<ROAR> Hear that? That’s Azeroth roaring. We quest, wander, laugh, and /roar at victories. Come join us!",
  "<ROAR> A guild of joyful explorers roaming Azeroth for stories, treasure, and good times. No rush, no pressure, just adventure and loud roars. Join now!",
  "<ROAR> The pride gathers! We celebrate level-ups, loot, sunsets, and silly moments with a good /roar. Casual adventures, big hearts. All welcome!",
  "<ROAR> Casual adventurers, loud celebrations, shared stories. If you like exploring Azeroth and roaring at people, you belong here!",
  "<ROAR> A guild for joy, curiosity, and shared stories. Quest, dungeon, PvP, RP, collect, and play together. Play to inspire, not to impress.",
  "<ROAR> Do you play for the world, not the meter? For stories, curiosity, and good vibes? We explore Azeroth together. Join us!",
  "<ROAR> We play to inspire, not to impress. A home for curious souls, shared adventures, and good energy across the world. Join now!",
  "<ROAR> Curious explorers and joyful wanderers wanted. We value respect, creativity, and shared stories. Let Azeroth hear your roar.",
  "<ROAR> Playing for curiosity, respect, and shared stories? So are we. Let's Roar together.",
  "<ROAR> Not in a hurry? Good. We wander, explore, and celebrate the journey with loud roars and good company.",
  "<ROAR> A casual guild for people who still enjoy getting lost in Azeroth. Stories, adventures, and plenty of /roar. Join!",
  "<ROAR> We chase moments, not meters. Quests, dungeons, wandering, laughter, and roaring along the way. Yall welcome!",
  "<ROAR> Join a pride that values curiosity, kindness, and shared adventures over rushing to the finish line.",
  "<ROAR> Azeroth is a world, not a checklist. Come explore it with us and roar when something great happens.",
  "<ROAR> From quiet wandering to loud celebrations, we enjoy every part of the journey together. Join our guild today!",
  "<ROAR> A home for explorers, storytellers, collectors, fighters, and friendly souls. We also roar a lot. Welcome to join!",
  "<ROAR> If you enjoy playing at your own pace and sharing the adventure, ROAR might be your new home. We are thrilled to get to know you!",
  "<ROAR> We celebrate the small wins, the big moments, and everything in between. We roar, together. Join us and roar along.",
  "<ROAR> Adventure feels better when shared - and roared. Explore Azeroth with us and let your voice be heard. ROAR!",
  "<ROAR> A pride of adventurers who savor the road, not the finish. We wander, wonder, and roar when the moment feels right.",
  "<ROAR> Where curiosity leads and joy follows. We share paths, stories, and the occasional very loud roar across Azeroth.",
  "<ROAR> For those who still stop to look at the skybox. We quest, linger, laugh, and roar together.",
  "<ROAR> A guild built on presence, kindness, and shared discovery. No rush. No pressure. Just the world and a good roar.",
  "<ROAR> We gather for the love of the world itself. Adventures unfold naturally, celebrations come loudly. Join the pride.",
  "<ROAR> A place for players who treat Azeroth like a living world. Stories over speed, connection over competition.",
  "<ROAR> Slow paths, shared campfires, sudden dungeons, triumphant roars. This is how we play.",
  "<ROAR> We believe the journey deserves applause. And that applause is a roar. Thats where we need your voice!",
  "<ROAR> A guild for wandering souls and grounded hearts. Come explore, stay curious, roar freely.",
  "<ROAR> We don’t chase perfection. We chase moments worth remembering—and we roar when we find them. Are you gonna roar with us?",
  "<ROAR> Azeroth feels bigger when explored together. We take our time and make some noise along the way. ROOAAR!",
  "<ROAR> From first steps to old roads revisited, we play with care, humor, and the occasional roar. Are you coming?",
  "<ROAR> A pride that values atmosphere, imagination, and shared presence. Adventures included. Roars guaranteed.",
  "<ROAR> If you enjoy meaningful play, relaxed pacing, and genuine company, you’ll fit right in. What are you waiting for, join!",
  "<ROAR> We roam with intention, celebrate with volume, and welcome with warmth. Join us.",
  "<ROAR> For adventurers who still listen to the music and read the quest text. We roar for the love of it. Get over here!",
  "<ROAR> A guild where small moments matter and big moments echo with roars. Are you ready?",
  "<ROAR> We play because the world is worth inhabiting. The roars are just a bonus. A big one tho! ROAR!",
  "<ROAR> Thoughtful adventuring, joyful chaos, shared victories. Come add your voice to the ROAR!",
  "<ROAR> No race. No grind mandate. Just Azeroth, companions, and a roar when it feels earned. Or just whenever actually.. like ofte.. very often..",
  "<ROAR> A home for players who value tone, respect, and shared discovery. ROAR mandatory. Cheers",
  "<ROAR> We wander first, optimize later, and roar whenever the spirit moves us. MOves you? join.",
  "<ROAR> Stories form naturally when you give them space. We give them space—and then roar.",
  "<ROAR> A pride shaped by curiosity, kindness, and collective memory. Join our journey.",
  "<ROAR> We treat Azeroth like a place, not a task list. Come walk it with us.",
  "<ROAR> From quiet evenings to loud triumphs, we share the whole rhythm of play. COme share yours!",
  "<ROAR> A guild that honors play as expression, not performance. Roaring encouraged.",
  "<ROAR> We make room for wandering, reflection, and sudden joy. Often loud joy. Very loud.",
  "<ROAR> If you play to feel the world rather than finish it, this is your guild. Share your journey with us!",
  "<ROAR> Adventures unfold better with patience, humor, and a good roar at the end.",
  "<ROAR> We celebrate effort, presence, and shared laughter more than outcomes.",
  "<ROAR> A guild for those who let moments breathe and victories echo.",
  "<ROAR> Play gently. Explore deeply. Roar honestly.",
  "<ROAR> We walk many paths, at many paces, with the same spirit.",
  "<ROAR> A pride built on shared time, mutual respect, and joyful noise.",
  "<ROAR> We don’t demand commitment—only curiosity and goodwill.",
  "<ROAR> Azeroth rewards those who listen. We listen, then roar.",
  "<ROAR> Where companionship matters more than efficiency. Come roam with us.",
  "<ROAR> A guild that believes joy is not a side effect, but the point.",
  "<ROAR> We wander Azeroth for joy, stories, and shared moments—and we’d love to have you with us. Come join the pride.",
  "<ROAR> Curious, relaxed, and a bit loud? We explore, laugh, and roar together. You’re welcome to join us.",
  "<ROAR> If you enjoy taking your time and sharing the adventure, there’s a place for you here. Come roam with ROAR.",
  "<ROAR> A friendly guild for explorers, storytellers, and joyful adventurers. All playstyles welcome—come join us.",
  "<ROAR> We play for the journey, not the rush. If that sounds right, come join us and roar along.",
  "<ROAR> Azeroth feels better together. We quest, wander, celebrate, and welcome new voices—join ROAR.",
  "<ROAR> Looking for a calm, curious guild with loud celebrations? You’re welcome to join our pride.",
  "<ROAR> From quiet wandering to big victories, we share it all. Come join us and make Azeroth louder.",
  "<ROAR> We value kindness, curiosity, and shared adventures. If that resonates, come join ROAR.",
  "<ROAR> A home for players who enjoy the world as much as the game. You’re welcome to join us.",
  "<ROAR> No pressure, no rush—just good company and shared stories. Come join the pride.",
  "<ROAR> We chase moments worth remembering and roar when they happen. Join us in Azeroth.",
  "<ROAR> Casual adventurers and curious souls wanted. All are welcome—come join ROAR.",
  "<ROAR> If you like exploring at your own pace and celebrating together, come join us.",
  "<ROAR> A guild built on joy, respect, and shared discovery. You’re always welcome to join.",
  "<ROAR> We believe Azeroth is a world meant to be lived in—come explore it with us.",
  "<ROAR> From first steps to familiar roads, we enjoy the journey together. Come join ROAR.",
  "<ROAR> We play to inspire, not to impress—and we’d love you to join us.",
  "<ROAR> A friendly pride for wandering, laughing, and loud roars. All welcome—come join.",
  "<ROAR> If you enjoy meaningful play and good company, there’s a spot for you here. Join ROAR.",
  "<ROAR> We celebrate small wins, big moments, and shared time. Come join us and roar along.",
  "<ROAR> Looking for a guild that values atmosphere over meters? You’re welcome to join.",
  "<ROAR> We take our time, enjoy the world, and make some noise. Come join the pride.",
  "<ROAR> A relaxed guild for people who still love getting lost in Azeroth. Join us.",
  "<ROAR> We roam, we wonder, we roar—and we’re always happy to welcome new adventurers.",
  "<ROAR> If Azeroth feels like a place, not a checklist, you’ll fit right in. Come join us.",
  "<ROAR> A home for explorers, fighters, collectors, and storytellers. You’re welcome to join.",
  "<ROAR> We value presence, curiosity, and shared joy. Come join ROAR and play with us.",
  "<ROAR> Adventure is better when shared—and louder. Come join us in Azeroth.",
  "<ROAR> No grind mandate, no rush—just shared adventures. You’re welcome to join the pride.",
  "<ROAR> We enjoy the whole journey, from quiet moments to loud triumphs. Join ROAR.",
  "<ROAR> A guild for relaxed play, good vibes, and shared stories. Come join us.",
  "<ROAR> If you’re looking for friendly faces and joyful adventures, you’re welcome here.",
  "<ROAR> We explore Azeroth together and celebrate along the way. Come join the pride.",
  "<ROAR> Play at your pace, share the adventure, and roar when it feels right. Join us.",
  "<ROAR> A welcoming guild for anyone who plays with curiosity and heart. Come join.",
  "<ROAR> We believe joy belongs at the center of play—and we invite you to join us.",
  "<ROAR> Looking for a warm, relaxed guild with loud celebrations? Come join ROAR.",
  "<ROAR> We roam, we explore, we laugh and adore—come join the pride and roar some more.",
  "<ROAR> Not in a rush, just wander and cheer—come join us friend, you’re welcome right here.",
  "<ROAR> We quest and we play, then roar at the day—come join our pride and stay your way.",
  "<ROAR> Through valleys and lore, we wander some more—come join the adventure and let out a roar.",
  "<ROAR> From sunrise to night, we share the delight—come join ROAR and play it just right.",
  "<ROAR> Some guilds min-max. We max the moment—and occasionally the volume. Come join us.",
  "<ROAR> Warning: joining may cause spontaneous roars, shared adventures, and unexpected joy. You’re welcome to join.",
  "<ROAR> We stroll and explore, then laugh and roar—come join our path and wander more.",
  "<ROAR> No need to race, just find your pace—come join our guild, this is the place.",
  "<ROAR> We quest, we cheer, the road is clear—come join us here, adventurer dear.",
  "<ROAR> Through hill and shore, we seek the lore—come join the fun and roar once more.",
  "<ROAR> We take it slow, let stories grow—come join ROAR and let it flow.",
  "<ROAR> From dawn to night, the vibes feel right—come join the pride and play it light.",
  "<ROAR> We roam the land, hand in hand—come join our guild, take a stand.",
  "<ROAR> Not here to grind, but unwind—come join ROAR and share the time.",
  "<ROAR> We laugh, we cheer, good friends are near—come join us now, your spot is here.",
  "<ROAR> The world feels wide when shared inside—come join our pride and enjoy the ride."
}



-------------------------------------------------
-- [2.2] Chat + Emote
-------------------------------------------------
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

-------------------------------------------------
-- [2.3] Profiles (Option C)
-------------------------------------------------
local function ROGU_ProfileKey()
  local name = UnitName("player") or "Unknown"
  local realm = (GetRealmName and GetRealmName()) or ""
  if realm == "" then return name end
  return name .. "-" .. realm
end

-- Shared (account-wide) master emote list defaults
local function ROGU_EnsureEmoteDefaults(db)
  if type(db.emotes) ~= "table" then db.emotes = {} end
  if table.getn(db.emotes) < 1 then
    db.emotes[1] = { emote = "ROAR" }
    return
  end

  if type(db.emotes[1]) ~= "table" or type(db.emotes[1].emote) ~= "string" or db.emotes[1].emote == "" then
    db.emotes[1] = { emote = "ROAR" }
  else
    db.emotes[1].emote = U.upper(db.emotes[1].emote)
    if db.emotes[1].emote == "" then db.emotes[1].emote = "ROAR" end
  end
end

local function ROGU_EnsureFallbackDefaultsOn(tbl)
  if type(tbl) ~= "table" then return end
  if tbl.enabled == nil then tbl.enabled = FALLBACK_DEFAULT.enabled end
  if tbl.cd == nil then tbl.cd = FALLBACK_DEFAULT.cd end
  if tbl.chancePermille == nil then tbl.chancePermille = FALLBACK_DEFAULT.chancePermille end
  if tbl.last == nil then tbl.last = 0 end
  if type(tbl.emoteIDs) ~= "table" or table.getn(tbl.emoteIDs) < 1 then
    tbl.emoteIDs = { 1 }
  end
end

local function ROGU_EnsureDB()
  if type(ROGUDB) ~= "table" then ROGUDB = {} end
  if type(ROGUDB.profiles) ~= "table" then ROGUDB.profiles = {} end
  ROGU_EnsureEmoteDefaults(ROGUDB)
  return ROGUDB
end

-- One-time migration from legacy root fields (older versions) into this character profile
local function ROGU_MigrateLegacyRootToProfile(db, p)
  if p._migrated == true then return end

  -- Legacy: db.slots, db.enabled, db.fallback (root)
  if type(db.slots) == "table" and type(p.slots) == "table" and next(p.slots) == nil then
    p.slots = db.slots
  end

  if db.enabled ~= nil and p.enabled == true then
    p.enabled = db.enabled
  end

  if type(db.fallback) == "table" then
    p.fallback = db.fallback
    ROGU_EnsureFallbackDefaultsOn(p.fallback)
  end

  -- Clear legacy roots to avoid two sources of truth
  db.slots = nil
  db.enabled = nil
  db.fallback = nil

  p._migrated = true
end

local function ROGU_EnsureProfile(db)
  local key = ROGU_ProfileKey()
  local p = db.profiles[key]
  if type(p) ~= "table" then
    p = {}
    db.profiles[key] = p
  end

  if p.enabled == nil then p.enabled = true end
  if type(p.slots) ~= "table" then p.slots = {} end
  if type(p.fallback) ~= "table" then p.fallback = {} end
  ROGU_EnsureFallbackDefaultsOn(p.fallback)

  ROGU_MigrateLegacyRootToProfile(db, p)

  return p, key
end

-------------------------------------------------
-- [2.4] Emote IDs sanitize + pick
-------------------------------------------------
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

-- keeps only unique numeric ids within [1..#db.emotes], ensures at least {1}
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

local function ROGU_PickEmoteForCfg(cfg)
  local db = ROGU_EnsureDB()
  local ids = (cfg and cfg.emoteIDs) or nil
  if type(ids) ~= "table" or table.getn(ids) < 1 then ids = { 1 } end

  local id = tonumber(ids[math.random(1, table.getn(ids))]) or 1
  local entry = (db.emotes and db.emotes[id]) or nil
  local token = (entry and entry.emote) or "ROAR"
  token = U.upper(token)
  if token == "" then token = "ROAR" end
  return token
end

-------------------------------------------------
-- [2.5] Load Once (bind runtime to current profile)
-------------------------------------------------
local function ROGU_LoadOnce()
  if ROGU._loaded then return end
  local db = ROGU_EnsureDB()
  local profile, key = ROGU_EnsureProfile(db)

  ROGU.profileKey = key
  ROGU.profile = profile
  ROGU.slots = profile.slots
  ROGU.fallback = profile.fallback
  ROGU.enabled = profile.enabled

  for _, cfg in pairs(ROGU.slots) do
    if cfg.chance == nil then cfg.chance = 100 end
    if cfg.cd == nil then cfg.cd = 6 end
    if cfg.last == nil then cfg.last = 0 end
    if type(cfg.emoteIDs) ~= "table" or table.getn(cfg.emoteIDs) < 1 then cfg.emoteIDs = { 1 } end
    ROGU_SanitizeEmoteIDs(cfg, db)
  end

  ROGU_SanitizeEmoteIDs(ROGU.fallback, db)

  ROGU._loaded = true
end

local function ROGU_SyncToProfile()
  if not ROGU.profile then return end
  ROGU.profile.enabled = ROGU.enabled
  ROGU.profile.slots = ROGU.slots
  ROGU.profile.fallback = ROGU.fallback
end
-------------------------------------------------
-- [2.6] Features
-------------------------------------------------
local function ROGU_SendInvite(channelNum)
  local msg = U.pick(inviteText)
  if not msg or msg == "" then return end

  local ch = tonumber(channelNum) or 1
  if ch < 1 then ch = 1 end
  if ch > 10 then ch = 10 end

  SendChatMessage(msg, "CHANNEL", nil, ch)
end

local function ROGU_DoBattleEmoteForCfg(cfg, now)
  if not ROGU.enabled or not cfg then return end

  cfg.last = cfg.last or 0
  if now - cfg.last < (cfg.cd or 0) then return end
  cfg.last = now

  if math.random(1,100) <= (cfg.chance or 0) then
    local token = ROGU_PickEmoteForCfg(cfg)
    performEmote(token)
    ROGU.lastRoar = now
  end
end

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
    performEmote(token)
    ROGU.lastRoar = now
    fb.last = now
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
  if not r then roarChat("No rest."); return end

  local m = UnitXPMax("player")
  if not m or m == 0 then roarChat("No XP data."); return end

  local bubbles = math.floor((r * 20) / m + 0.5)
  if bubbles > 30 then bubbles = 30 end

  roarChat("Rest: "..bubbles.." bubbles ("..r.." XP)")
end

-------------------------------------------------
-- [3] Hook UseAction
-------------------------------------------------
local _Orig_UseAction = UseAction

function UseAction(slot, checkCursor, onSelf)
  ROGU_LoadOnce()
  local now = GetTime()

  if ROGU.watchMode then
    roarChat("pressed slot "..tostring(slot))
  end

  for _, cfg in pairs(ROGU.slots) do
    if cfg.slot == slot then
      ROGU_DoBattleEmoteForCfg(cfg, now)
    end
  end

  -- Always-active independent fallback
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

  if cmd == "INVITE" then
  local ch = U.trim(rest or "")
  if ch == "" then ch = "1" end
  ROGU_SendInvite(ch)
  return
  end

  -- /rogu emote <TOKEN> | /rogu emote list
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
    if not instance then roarChat("invalid instance"); return end

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
        local tok = (db.emotes[id] and db.emotes[id].emote) or "ROAR"
        if out ~= "" then out = out.." | " end
        out = out..tostring(id)..":"..U.upper(tok)
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
      local cfg = ROGU.slots[instance]
      cfg.slot = slot
      cfg.chance = cfg.chance or 100
      cfg.cd = cfg.cd or 6
      cfg.last = 0
      ROGU_SanitizeEmoteIDs(cfg, db)
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
    if ROGU.profile then
      ROGU.profile.slots = ROGU.slots
    end
    roarChat("all instances cleared")
    return
  end
  -- /rogu resetcd reset all cooldowns
  if cmd == "RESETCD" then
  local now = GetTime()

  -- reset per-instance cooldown gates
  for _, cfg in pairs(ROGU.slots or {}) do
    if type(cfg) == "table" then
      cfg.last = 0
    end
  end

  -- reset fallback throttle too
  if type(ROGU.fallback) == "table" then
    ROGU.fallback.last = 0
  end

  -- reset reminder timers (optional but sane)
  ROGU.lastRoar = 0
  ROGU.lastReminder = 0

  ROGU_SyncToProfile()
  roarChat("cooldowns reset")
  return
end

  if cmd == "INFO" then
    roarChat("version: "..ADDON_VERSION)
    roarChat("profile: "..tostring(ROGU.profileKey or "?"))
    roarChat("enabled: "..tostring(ROGU.enabled))
    roarChat("emotes in DB: "..tostring(table.getn(db.emotes)))

    if type(ROGU.fallback) == "table" then
      local fb = ROGU.fallback
      ROGU_SanitizeEmoteIDs(fb, db)
      local fbids = ""
      local k = 1
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

  if cmd == "ON" then
    ROGU.enabled = true
    ROGU_SyncToProfile()
    roarChat("enabled")
    return
  end

  if cmd == "OFF" then
    ROGU.enabled = false
    ROGU_SyncToProfile()
    roarChat("disabled")
    return
  end

  if cmd == "REXP" then
    ROGU_ReportRestedXP()
    return
  end

  if cmd == "ROAR" then
    local token = ROGU_PickEmoteForCfg(ROGU.slots[1] or { emoteIDs={1} })
    performEmote(token)
    ROGU.lastRoar = GetTime()
    return
  end

  roarChat(" invite <1-10> | slotX <n> | chanceX <0-100> | timerX <sec> | emote <TOKEN> | emote list | emoteX <id|-id|clear|list> | watch | info | reset | resetcd | on | off | rexp | roar")

end

-------------------------------------------------
-- [5] Init / Save
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime() * 1000))
    math.random()

    -- ensure profile exists early
    ROGU_LoadOnce()

    -- reset all cooldown gates on login
    for _, cfg in pairs(ROGU.slots or {}) do
      if type(cfg) == "table" then
        cfg.last = 0
      end
    end

    if type(ROGU.fallback) == "table" then
      ROGU.fallback.last = 0
    end

    ROGU.lastRoar = 0
    ROGU.lastReminder = 0

    ROGU_SyncToProfile()

  elseif event == "PLAYER_LOGOUT" then
    ROGU_SyncToProfile()
  end
end)

