-- RoarGuild v1.32 
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariables: ROGUDB

-------------------------------------------------
-- [0] Constants
-------------------------------------------------
local ADDON_VERSION = "1.32"

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

  stats = nil,          -- bound to profile.stats
  
  lastRoar = 0,
  lastReminder = 0,

  _loaded = false,
}

-------------------------------------------------
-- [2.1] Data Pools
-------------------------------------------------
local inviteText = {
  "<ROAR> Raise your cup and stake your claim, we walk for wonder, fire, and flame. Through mud and march and starlit sky, we roar so loud the hills reply.",
  "<ROAR> Hear that thunder on the plain, not from storm or falling rain. It is laughter fierce and bright, come step inside and join the fight.",
  "<ROAR> When moments blaze in golden core, we answer back with living roar.",
  "<ROAR> Caverns deep and battle cry, tavern cheers that shake the sky. We play with heart, we stand with flame, and joy is more than hollow fame.",
  "<ROAR> Inspire bold and stand up proud, let courage speak both clear and loud. When tankards strike and sparks ignite, one great roar will claim the night.",
  "<ROAR> No frantic drum, no hollow race, we claim the road at chosen pace. Yet when the hour demands the sound, our thunder shakes the very ground.",
  "<ROAR> We chase the spark in fleeting glance, in dungeon crawl and daring chance. When meaning strikes like tempered steel, we roar to show the world it is real.",
  "<ROAR> Love the world in all its might, in clash of steel and star lit night. When glory blooms in burning core, we answer back with thunderous roar.",
  "<ROAR> Slow the step but feed the fire, strike as one when hearts aspire. Warm the camp and storm the gate, fierce together, bold and great.",
  "<ROAR> The journey earns a warrior cheer, not timid clap but thunder clear. Lift your voice and shake the floor, and let it crash in mighty roar.",
  "<ROAR> We chase not brittle fleeting fame, but blazing moments none can tame. When we find them walls will shake, and mountains hear the sound we make.",
  "<ROAR> Hear the music in the fight, read the quest by torch and light. Love the world with fearless core, and let it hear your battle roar.",
  "<ROAR> Sparks grow tall to blazing sky, great victories thunder high. Echo long till dawn is born, come forge your legend in the storm.",
  "<ROAR> Respect in word and fire in chest, discovery lived and loudly blessed. Stand upright and claim your sound, let your echo shake the ground.",
  "<ROAR> The world rewards the watchful ear, we listen close then answer clear. When silence falls and shadows pour, we split the dark with blazing roar.",
  "<ROAR> Above all else we choose the flame, the joy that sets the night aflame. Not a whisper, not a sigh, but a roar that shakes the sky.",
  "<ROAR> That rolling sound across the plain is not thundercloud nor storm nor rain, it is laughter ringing bright and raw from quests well fought and things we saw, if that deep echo feels like home, step near the fire no need to roam.",
  "<ROAR> And when the tankards strike the floor we answer back with one great roar.",
  "<ROAR> Good company and spirits sure and roars that echo strong and pure.",
  "<ROAR> If moments matter more than score then you belong with ROAR.",
  "<ROAR> Add your voice both fierce and clear and make the mountains lean to hear.",
  "<ROAR> The journey deserves applause, and we do not clap quietly. We roar. Lift your voice and mean it.",
  "<ROAR> We do not chase perfection. We chase moments worth remembering. When we find them, we make the walls tremble.",
  "<ROAR> We roam with intention, celebrate with volume, and welcome with warmth. There is always space at this table.",
  "<ROAR> To thoughtful steps, joyful chaos, and victories shared. Add your voice and do not hold back.",
  "<ROAR> Azeroth rewards those who listen. We listen close, then we answer back loud.",
  "<ROAR> Calm company with the promise of thunder when needed. That balance is rare. I intend to keep it.",
  "<ROAR> Small victories deserve acknowledgment. Large victories deserve thunder. Both deserve witnesses.",
  "<ROAR> Warm company. Steady pace. And when the moment calls for it, a roar that makes the rafters answer back.",
  "<ROAR> To shields held high through long marches, boots worn thin on old roads, and ale earned the honest way. May our paths stay winding and our laughter outlast the night.",
  "<ROAR> To strength proven when it mattered, honor kept both in battle and at the table and meat roasted exactly as it should be.",
  "<ROAR> To scars earned honestly, bonds forged in hardship, and mugs emptied without hesitation or regret.",
  "<ROAR> To surviving what should have ended us, savoring what remains, and laughing in defiance of it all.",
  "<ROAR> Strength with respect rings clear and wide, a steady thunder none can hide. Bring that sound and make it soar, join your voice within the ROAR.",
  "<ROAR> Bonds in trial, bonds in flame, outlast glory, outlast fame. Walk with us through thick and thin, and find the pride that waits within.",
  "<ROAR> Borrowed hours still can shine, lift a mug and cross the line. If joy calls out across the floor, answer back with a fearless roar.",
  "<ROAR> Keep the fire against the cold, let stories rise and hands be bold. In leaner years and brighter days, we gather close and lift our praise.",
  "<ROAR> Temper strength with open hand, let respect in power stand. When your voice rings true and deep, others wake from guarded sleep.",
  "<ROAR> Trials passed and hardships crossed, forge a bond no war has lost. Through every chain and shadowed year, we choose to gather rather than fear.",
  "<ROAR> Time is brief but joy is bright, claim it boldly in the night. Laugh out loud and stand up tall, let your voice be heard by all.",
  "<ROAR> When drums fall still and spirits hear, joy is what draws them near. Bring your cheer and let it pour, answer back with ROAR on ROAR.",

  "<ROAR> We roam, we explore, we laugh and adore, come join the pride and roar some more.",
  "<ROAR> Not in a rush, just wander and cheer, come join us friend, you are welcome right here.",
  "<ROAR> We quest and we play, then roar at the day, come join our pride and stay your way.",
  "<ROAR> Through valleys and lore, we wander some more, come join the adventure and let out a roar.",
  "<ROAR> From sunrise to night, we share the delight, come join ROAR and play it just right.",
  "<ROAR> Warning: joining may cause spontaneous roars, shared adventures, and unexpected joy. You are welcome to join.",
  "<ROAR> We stroll and explore, then laugh and roar, come join our path and wander more.",
  "<ROAR> No need to race, just find your pace, come join our guild, this is the place.",
  "<ROAR> We quest, we cheer, the road is clear, come join us here, adventurer dear.",
  "<ROAR> Through hill and shore, we seek the lore, come join the fun and roar once more.",
  "<ROAR> We take it slow, let stories grow, come join ROAR and let it flow.",
  "<ROAR> From dawn to night, the vibes feel right, come join the pride and play it light.",
  "<ROAR> We roam the land, hand in hand, come join our guild, take a stand.",
  "<ROAR> Not here to grind, but unwind? Come join ROAR and share the time.",
  "<ROAR> We laugh, we cheer, good friends are near, come join us now, your spot is here.",
  "<ROAR> The world feels wide when shared inside, come join our pride and enjoy the ride."
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
-- [2.3] Profiles 
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

  -- Per-character stats (rolling hour + lifetime total)
  if type(p.stats) ~= "table" then p.stats = {} end
  if p.stats.total == nil then p.stats.total = 0 end
  if type(p.stats.stamps) ~= "table" then p.stats.stamps = {} end
  if p.stats.head == nil then p.stats.head = 1 end
  if p.stats.lastReport == nil then p.stats.lastReport = 0 end

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
-- [2.4.9] Forward declarations for stats
-------------------------------------------------
local ROGU_StatsRecordEmote
local ROGU_StatsPerMinuteLastHour
local ROGU_StatsMaybeHourlyReport_OnActivity

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
  ROGU.stats = profile.stats


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
  ROGU.profile.stats = ROGU.stats
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

    if ROGU_StatsRecordEmote then
      ROGU_StatsRecordEmote()
    end
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

    if ROGU_StatsRecordEmote then
      ROGU_StatsRecordEmote()
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
  if not r then roarChat("No rest."); return end

  local m = UnitXPMax("player")
  if not m or m == 0 then roarChat("No XP data."); return end

  local bubbles = math.floor((r * 20) / m + 0.5)
  if bubbles > 30 then bubbles = 30 end

  roarChat("Rest: "..bubbles.." bubbles ("..r.." XP)")
end


-------------------------------------------------
-- [2.7] Stats: lifetime total + rolling last hour
-------------------------------------------------

local STATS_WINDOW = 3600
local STATS_REPORT_INTERVAL = 3600

local function ROGU_Now()
  if time then return time() end
  return math.floor(GetTime())
end

local function ROGU_StatsPrune(now)
  local s = ROGU.stats
  if type(s) ~= "table" or type(s.stamps) ~= "table" then return end

  local cutoff = now - STATS_WINDOW
  local stamps = s.stamps
  local head = tonumber(s.head) or 1
  if head < 1 then head = 1 end

  while stamps[head] and stamps[head] <= cutoff do
    head = head + 1
  end
  s.head = head

  -- compact occasionally so stamps doesn't grow forever
  local n = table.getn(stamps)
  if head > 50 and head > math.floor(n / 2) then
    local out = {}
    local j = 1
    local i = head
    while stamps[i] do
      out[j] = stamps[i]
      j = j + 1
      i = i + 1
    end
    s.stamps = out
    s.head = 1
  end
end

local function ROGU_StatsCountLastHour()
  local s = ROGU.stats
  if type(s) ~= "table" or type(s.stamps) ~= "table" then return 0 end
  local n = table.getn(s.stamps)
  local head = tonumber(s.head) or 1
  if head < 1 then head = 1 end
  local c = n - head + 1
  if c < 0 then c = 0 end
  return c
end

ROGU_StatsRecordEmote = function()
  local s = ROGU.stats
  if type(s) ~= "table" then return end

  local now = ROGU_Now()
  if type(s.stamps) ~= "table" then s.stamps = {} end
  if s.head == nil then s.head = 1 end
  if s.total == nil then s.total = 0 end

  s.total = s.total + 1
  s.stamps[table.getn(s.stamps) + 1] = now

  -- keep rolling window clean on each emote
  ROGU_StatsPrune(now)
end

ROGU_StatsPerMinuteLastHour = function()
  local now = ROGU_Now()
  ROGU_StatsPrune(now)
  return ROGU_StatsCountLastHour() / 60
end

ROGU_StatsMaybeHourlyReport_OnActivity = function()
  local s = ROGU.stats
  if type(s) ~= "table" then return end

  local now = ROGU_Now()
  ROGU_StatsPrune(now)

  s.lastReport = tonumber(s.lastReport) or 0
  if s.lastReport == 0 then
    s.lastReport = now
    return
  end

  if now - s.lastReport < STATS_REPORT_INTERVAL then return end

  local count = ROGU_StatsCountLastHour()
  local perMin = count / 60
  local total = tonumber(s.total) or 0
  roarChat("total roars: "..tostring(total).." | last hour: "..tostring(count).." ("..string.format("%.1f", perMin).." per minute)")

  s.lastReport = now
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

  -- Stats: prune + hourly report gate (only on slot activity)
  ROGU_StatsMaybeHourlyReport_OnActivity()


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

  -------------------------------------------------
  -- [4.1] Core: help / info / enable
  -------------------------------------------------
  if cmd == "" or cmd == "HELP" then
    roarChat(" invite <1-10> | slotX <n> | chanceX <0-100> | timerX <sec> | fallback chance <0-1000> | fallback timer <sec> | emote <TOKEN> | emote list | emoteX <id|-id|clear|list> | watch | info | reset | resetcd | on | off | rexp | roar")
    return
  end

  if cmd == "INFO" then
    roarChat("version: "..ADDON_VERSION)
    roarChat("profile: "..tostring(ROGU.profileKey or "?"))
    roarChat("enabled: "..tostring(ROGU.enabled))
    roarChat("emotes in DB: "..tostring(table.getn(db.emotes)))

  local s = ROGU.stats
    if type(s) ~= "table" then
      roarChat("stats: not initialized")
    else
      local total = tonumber(s.total) or 0
      local perMin = 0
      if ROGU_StatsPerMinuteLastHour then
        perMin = ROGU_StatsPerMinuteLastHour()
      end
      roarChat("total roars: "..tostring(total))
      roarChat("last hour: "..string.format("%.1f", perMin).." per minute")
    end



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

  -------------------------------------------------
  -- [4.2] Social: invite + manual roar
  -------------------------------------------------
  if cmd == "INVITE" then
    local ch = U.trim(rest or "")
    if ch == "" then ch = "1" end
    ROGU_SendInvite(ch)
    return
  end

  if cmd == "ROAR" then
    local token = ROGU_PickEmoteForCfg(ROGU.slots[1] or { emoteIDs={1} })
    performEmote(token)
    if ROGU_StatsRecordEmote then
      ROGU_StatsRecordEmote()
    end
ROGU.lastRoar = GetTime()
return
  end

  -------------------------------------------------
  -- [4.3] Utility: rested XP
  -------------------------------------------------
  if cmd == "REXP" then
    ROGU_ReportRestedXP()
    return
  end

  -------------------------------------------------
  -- [4.4] Debug: watch pressed slots
  -------------------------------------------------
  if cmd == "WATCH" then
    ROGU.watchMode = not ROGU.watchMode
    roarChat("watch mode "..(ROGU.watchMode and "ON" or "OFF"))
    return
  end

  -------------------------------------------------
  -- [4.4.5] Fallback config: chance / timer
  -------------------------------------------------
  if cmd == "FALLBACK" then
    local sub, subrest = U.split_cmd(rest or "")
    sub = U.upper(sub)
    local fb = ROGU.fallback
    if type(fb) ~= "table" then
      fb = {}
      ROGU.fallback = fb
      ROGU_EnsureFallbackDefaultsOn(fb)
    end

    if sub == "CHANCE" then
      local n = tonumber(subrest)
      if n and n >= 0 and n <= 1000 then
        fb.chancePermille = n
        roarChat("fallback chance "..tostring(n).."/1000")
      else
        roarChat("usage: /rogu fallback chance <0-1000>")
      end
      return
    end

    if sub == "TIMER" then
      local n = tonumber(subrest)
      if n and n >= 0 then
        fb.cd = n
        roarChat("fallback cooldown "..tostring(n).."s")
      else
        roarChat("usage: /rogu fallback timer <sec>")
      end
      return
    end

    roarChat("usage: /rogu fallback chance <0-1000> | /rogu fallback timer <sec>")
    return
  end

  -------------------------------------------------
  -- [4.5]Instance config: slotX / chanceX / timerX
  -------------------------------------------------
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

  -------------------------------------------------
  -- [4.6]Emote DB: add + list
  -------------------------------------------------
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

  -------------------------------------------------
  -- [4.7]Instance emote selection: emoteX add/remove/clear/list
  -------------------------------------------------
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

  -------------------------------------------------
  -- [4.8]Maintenance: reset instances / reset cooldown gates
  -------------------------------------------------
  if cmd == "RESET" then
    ROGU.slots = {}
    if ROGU.profile then
      ROGU.profile.slots = ROGU.slots
    end
    roarChat("all instances cleared")
    return
  end

  if cmd == "RESETCD" then
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

    -- reset reminder timers
    ROGU.lastRoar = 0
    ROGU.lastReminder = 0

    ROGU_SyncToProfile()
    roarChat("cooldowns reset")
    return
  end

  roarChat(" invite <1-10> | slotX <n> | chanceX <0-100> | timerX <sec> | fallback chance <0-1000> | fallback timer <sec> | emote <TOKEN> | emote list | emoteX <id|-id|clear|list> | watch | info | reset | resetcd | on | off | rexp | roar")
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
