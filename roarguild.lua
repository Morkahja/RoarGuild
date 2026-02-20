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
  "<ROAR> Friendly hearts and curious minds, we walk for wonder not for signs, no counting meters no racing clocks, just steady boots on winding rocks, when moments bloom in ember light, we lift our voices to the night.",
  "<ROAR> That rolling sound across the plain is not thundercloud nor storm nor rain, it is laughter ringing bright and raw from quests well fought and things we saw, if that deep echo feels like home, step near the fire no need to roam.",
  "<ROAR> We hunt for stories not for speed, for treasure wrapped in laugh and deed, no pressure set no breath held tight, just open road and hearthfire light, and when the tale turns bold and bright, we roar it proudly through the night.",
  "<ROAR> The roar gathers mugs held high for fallen foes and painted sky, for clumsy pulls and epic loot, for triumph earned in dusty boot, steady hearts and open door, all are welcome to the roar.",
  "<ROAR> Casual steps and thunder cheer, shared old tales and friends held near, if wandering roads make your spirit sing and noise feels like a natural thing, then by the forge and foaming glass you have found your kin at last.",
  "<ROAR> Quests and caverns blades and lore, battlefields and tavern floor, stories stirred in iron stew, we play for meaning deep and true, not to impress with shining name but to set the coals of joy aflame.",
  "<ROAR> If you sit for sky and song, for quiet paths that wind along, for wonder bright and laughter free, then pull a chair and sit with me, no ledger tallied no score to chase, just world enough and shared hearthspace.",
  "<ROAR> Inspire first and boast not loud, stand steady not above the crowd, curious souls in warm embrace, shared adventure unhurried pace, and when the tankards strike the floor we answer back with one great roar.",
  "<ROAR> Explorers bright and wanderers wide, bring your craft and stand beside, respect the road create with care, let your story fill the air, lift your voice and let it soar, let Azeroth resound with ROAR.",
  "<ROAR> Curiosity in common hand, respect the ground on which we stand, shared stories told in firelight glow, step by step the long roads go, if that same taste is in your core, come walk the miles with ROAR.",
  "<ROAR> No rushing drum no frantic cry, we let the seasons wander by, we roam we toast we laugh out loud, unburdened by the pressing crowd, good company and spirits sure and roars that echo strong and pure.",
  "<ROAR> For those who lose themselves with grace in forest shade or desert space, who read the lines and hear the song and do not mind the road is long, there is story ale and open door and always room for one more roar.",
  "<ROAR> We chase the spark in fleeting glance, in dungeon crawl and roadside chance, not numbers tallied cold and dry but laughter flung against the sky, if moments matter more than score then you belong with ROAR.",
  "<ROAR> Azeroth is living ground not boxes checked nor trophies found, so walk it slow let wonder start and roar when fire fills your heart, for when a moment turns out fine we mark it loud with ale and sign.",
  "<ROAR> From hushed twilight to cheering flame we share the rhythm just the same, soft footfalls battle cries, warm embraces open skies, in every tone from low to high together let our voices fly.",
  "<ROAR> Explorers crafters blades held fast, storytellers of future and past, collectors dreamers gentle might, all find a seat in hearthfire light, pull a chair and stay a while, we roar in grief we roar in smile.",
  "<ROAR> At your own pace the road may bend with steady kin and honest friend, share the weight and share the view, let the wide world open to you, if that is how you choose to soar then step your boots inside our door.",
  "<ROAR> Small triumphs vast victories, quiet glances grand histories, if it stirs the soul at all we answer with a thunder call, add your voice both fierce and clear and make the mountains lean to hear.",

  "<ROAR> Adventure shared tastes rich and deep like ale long brewed and well earned sleep, so wander wide where wild winds sweep and promises are ours to keep, raise your mug and claim your part, roar from iron roast and heart.",
  "<ROAR> Raise your mug to the long road, not the finish line. We savor the miles, the mud on our boots, and when the moment turns sweet, we answer it with a roar.",
  "<ROAR> To curiosity that pulls us forward and joy that follows close behind. May our paths cross often, our stories grow bold, and our roars shake the rafters.",
  "<ROAR> To those who still look up at the sky between battles. May your quests be rich, your laughter loud, and your roars shared shoulder to shoulder.",
  "<ROAR> To presence over pressure, kindness over haste. No rush in this hall, only the wide world and a roar when it earns one.",
  "<ROAR> To loving the world for what it is. Let adventures unfold as they will, and when they bloom, we celebrate them properly and loudly.",
  "<ROAR> To those who treat Azeroth as living ground. Stories over speed, bonds over bragging. Drink to that.",
  "<ROAR> To slow roads, warm campfires, sudden dungeons, and the kind of triumph that deserves a table full of noise.",
  "<ROAR> The journey deserves applause, and we do not clap quietly. We roar. Lift your voice and mean it.",
  "<ROAR> To wandering souls with steady hearts. Stay curious, roam wide, and never swallow a roar that wants to be heard.",
  "<ROAR> We do not chase perfection. We chase moments worth remembering. When we find them, we make the walls tremble.",
  "<ROAR> To Azeroth grown larger by shared footsteps. We take our time, and we make enough noise to prove we were there.",
  "<ROAR> From first timid step to well worn road, may we play with care, humor, and a roar ready on the tongue.",
  "<ROAR> To atmosphere thick as stout, imagination bright as forgefire, and presence that fills a room before a word is spoken.",
  "<ROAR> To meaningful play and unhurried pace. If you value good company over hollow glory, your seat is waiting.",
  "<ROAR> We roam with intention, celebrate with volume, and welcome with warmth. There is always space at this table.",
  "<ROAR> To those who hear the music and read the fine print of a quest. May your love of the world be loud and honest.",
  "<ROAR> To small moments that matter and great victories that echo. Come make echoes with us.",
  "<ROAR> We play because the world is worth living in. The roars are just the bonus, and a grand one at that.",
  "<ROAR> To thoughtful steps, joyful chaos, and victories shared. Add your voice and do not hold back.",
  "<ROAR> No races here, no grind chains on your boots. Just companions, a wide horizon, and a roar when it feels right. Or whenever the mood strikes.",
  "<ROAR> To tone kept steady, respect kept strong, and discovery shared freely. Roaring is encouraged, sulking is not.",
  "<ROAR> We wander first and count later. When the spirit stirs, we answer it with sound.",
  "<ROAR> Give a story space and it will grow. Give it friends and it will thunder.",
  "<ROAR> To a pride shaped by curiosity and kindness, and by memories that taste better with time.",
  "<ROAR> Azeroth is a place to walk, not a list to scratch through. So walk it well and walk it together.",
  "<ROAR> From quiet evenings to roaring triumphs, we share the whole rhythm of it. None of it wasted.",
  "<ROAR> Play as craft, not performance. Let your roar be real, not rehearsed.",
  "<ROAR> To wandering thoughts, sudden joy, and the kind of laughter that spills ale.",
  "<ROAR> If you play to feel the world under your boots, you will not drink alone here.",
  "<ROAR> Patience, humor, and a roar at the end of a hard earned tale. That is how a night should close.",
  "<ROAR> We raise mugs to effort, to presence, and to laughter shared, not just to outcomes.",
  "<ROAR> To those who let moments breathe and let victories echo until dawn.",
  "<ROAR> Play gently, explore deeply, and roar honestly. Nothing less.",
  "<ROAR> Many paths, many paces, one steady spirit binding us together.",
  "<ROAR> Shared time, mutual respect, and joyful noise. That is the foundation under this roof.",
  "<ROAR> No oaths demanded, only curiosity and goodwill. That is enough.",
  "<ROAR> Azeroth rewards those who listen. We listen close, then we answer back loud.",
  "<ROAR> To companionship over efficiency. To walking together rather than racing alone.",
  "<ROAR> And above all, to joy. Not as a side effect, but as the whole reason we lift these mugs at all.",

  "<ROAR> Tonight I was thinking how we wander this world not for coin or glory, but for the taste of it. The stories, the shared miles, the sound of boots beside our own. It is better that way. The road feels lighter with company.",
  "<ROAR> I have noticed a pattern. The curious ones linger. The relaxed ones laugh easier. The loud ones never truly leave. Those are my kind of people. They fit without trying.",
  "<ROAR> There is something honest about taking your time. Letting an adventure breathe. Sharing it instead of rushing through it. That is how I want this pride to feel.",
  "<ROAR> Different callings, different blades, different crafts. Yet when they sit at the same table, the noise turns warm instead of sharp. I like that. Every style welcome, so long as the heart is steady.",
  "<ROAR> I do not care for haste. The journey itself has weight and flavor. If we must roar, let it be because the moment deserves it, not because we ran too fast to notice it.",
  "<ROAR> Azeroth grows when walked together. I have seen it. New voices, new laughter, new stories folded into the old ones. It makes the world feel less lonely.",
  "<ROAR> Calm company with the promise of thunder when needed. That balance is rare. I intend to keep it.",
  "<ROAR> Some days are quiet. Some nights shake the rafters. I want both. The stillness and the triumph. The soft talk and the roaring celebration.",
  "<ROAR> Kindness is a sturdier foundation than ambition. Curiosity keeps the doors open. Shared adventure keeps the hearth burning.",
  "<ROAR> There are those who enjoy the world itself, not just the game of it. I recognize them by the way they pause. Those are the ones I save a seat for.",
  "<ROAR> No pressure here. No measuring worth in numbers. Just stories told honestly and laughter that rolls without shame.",
  "<ROAR> We chase moments that linger. The kind that stay warm in memory. When we find one, we mark it properly.",
  "<ROAR> I do not need heroes polished bright. I need curious souls willing to walk beside others. That is enough.",
  "<ROAR> Everyone moves at their own pace. The pride should stretch wide enough to hold that. Exploration shared is exploration doubled.",
  "<ROAR> Joy, respect, discovery. Simple words. Hard to maintain without care. I will maintain them.",
  "<ROAR> This world is meant to be lived in, not harvested. I remind myself of that often.",
  "<ROAR> From first uncertain steps to old roads walked again, I find comfort in familiar company beside me.",
  "<ROAR> We play to inspire each other. Not to impress strangers. That difference matters.",
  "<ROAR> Laughter carries far in stone halls. I want these halls remembered for it.",
  "<ROAR> Meaningful play requires presence. Good company makes presence easy.",
  "<ROAR> Small victories deserve acknowledgment. Large victories deserve thunder. Both deserve witnesses.",
  "<ROAR> I will always choose atmosphere over empty numbers. A living world over a finished list.",
  "<ROAR> Time taken is not time wasted. Especially when shared.",
  "<ROAR> Getting lost is not failure. It is often where the best stories begin.",
  "<ROAR> We roam. We wonder. We roar. And I am always glad when a new pair of boots crosses the threshold.",
  "<ROAR> When someone treats this land as a place instead of a task, I notice. They usually stay.",
  "<ROAR> Explorers, fighters, collectors, storytellers. Different hands, same table.",
  "<ROAR> Presence matters. Curiosity matters. Shared joy matters more than most things.",
  "<ROAR> Adventure grows richer when spoken about later, louder than before.",
  "<ROAR> I will never bind this pride to a grind. Only to shared steps and willing hearts.",
  "<ROAR> The quiet moments are as important as the loud ones. Both shape us.",
  "<ROAR> Relaxed play leaves room for honesty. Honesty leaves room for connection.",
  "<ROAR> There is always space for another warm presence near the fire.",
  "<ROAR> Exploring together changes the weight of the world. It becomes carryable.",
  "<ROAR> Each should move at their own rhythm. The roar will come naturally.",
  "<ROAR> Curiosity and heart. That is the measure I trust.",
  "<ROAR> Joy must sit at the center. Otherwise the rest tastes hollow.",
  "<ROAR> Warm company. Steady pace. And when the moment calls for it, a roar that makes the rafters answer back.",

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
  "<ROAR> The world feels wide when shared inside, come join our pride and enjoy the ride.",

  "<ROAR> To ancient songs remembered, blades kept keen, and dignity carried even in exile. May our cups shine as bright as the legacy we refuse to forget.",
  "<ROAR> To vigilance without bitterness, honor without a homeland, and nights where old histories rest quietly beside new friendships.",
  "<ROAR> To deals sealed with a grin, risks taken with confidence, and feasts funded by clever timing. Gold comes and goes, but a good celebration pays dividends.",
  "<ROAR> To sharp instincts, quicker tongues, and victories toasted loud before the numbers are even counted.",
  "<ROAR> To shields held high through long marches, boots worn thin on old roads, and ale earned the honest way. May our paths stay winding and our laughter outlast the night.",
  "<ROAR> To songs sung after battle, friends gathered close at the table, and stories retold until they grow warmer with every telling raise your glass.",
  "<ROAR> To stone halls remembered, strong arms still steady, and mugs that are never empty for long. May the echoes of our laughter rival any mountain hall.",
  "<ROAR> To hearthfires glowing late, old tales shared freely, and victories celebrated with open smiles and full cups.",
  "<ROAR> To ancient paths walked once more, moonlit camps beneath quiet stars, and the patience that lets wonder unfold at its own pace.",
  "<ROAR> To starlight through the leaves, calm breaths between battles, and moments of stillness shared among trusted companions.",
  "<ROAR> To clever plans that somehow worked, spectacular mistakes we still laugh about, and triumphs worth rebuilding half the camp for.",
  "<ROAR> To sparks of inspiration, quick hands, bright minds, and feasts frequently interrupted by new ideas.",
  "<ROAR> To strength proven when it mattered, honor kept both in battle and at the table and meat roasted exactly as it should be.",
  "<ROAR> To scars earned honestly, bonds forged in hardship, and mugs emptied without hesitation or regret.",
  "<ROAR> To spirits who guide our steps, the land that carries us forward, and journeys shared in balance and respect.",
  "<ROAR> To steady hearts, quiet wisdom, and celebrations that feel less like victory and more like home.",
  "<ROAR> To surviving what should have ended us, savoring what remains, and laughing in defiance of it all.",
  "<ROAR> To borrowed time, sharp humor, and feasts enjoyed fully, because tomorrow is never promised.",
  "<ROAR> To clever tricks pulled off just in time, drums beaten late into the night, and stories that grow wilder with every retelling.",
  "<ROAR> To dancing firelight, joyful chaos, and nights that stretch on until dawn finds us still laughing.",

  "<ROAR> Ask the question, cross the span, build bright bridges where you stand. Curiosity lights the door, step inside and roar once more.",

"<ROAR> Share your craft and share your spark, let no bright idea stay in the dark. Laugh and build and try anew, we have a place prepared for you.",

"<ROAR> Strength with respect rings clear and wide, a steady thunder none can hide. Bring that sound and make it soar, join your voice within the ROAR.",

"<ROAR> Bonds in trial, bonds in flame, outlast glory, outlast fame. Walk with us through thick and thin, and find the pride that waits within.",

"<ROAR> Tread the land with mindful stride, let care and courage be your guide. The world remembers gentle might, come roam with us in shared delight.",

"<ROAR> True strength grows where hearts align, in shared laughter over ale and time. Stand together, firm and free, and add your voice to our company.",

"<ROAR> Choose a meaning bright and clear, hold it close and keep it near. In darkest hours we still explore, come shape the tale we are living for.",

"<ROAR> Borrowed hours still can shine, lift a mug and cross the line. If joy calls out across the floor, answer back with a fearless roar.",

"<ROAR> Tell your story by the flame, let it wander, let it change. Stories shared grow strong and wide, come speak yours beside the pride.",

"<ROAR> When drums fall still and night grows deep, joy is what the spirits keep. Bring your laughter, bright and pure, and let it echo ever sure.",

"<ROAR> Old traditions breathe and grow when new voices join the flow. Bring your song and let it ring, add your note to everything.",

"<ROAR> Grace is carried hand in hand, across each sea and shifting sand. Walk with us through loss and lore, and find your place within the ROAR.",

"<ROAR> Gold may fade and coins may fall, but good names echo through it all. Build your tale with steady core, and let it thunder with the ROAR.",

"<ROAR> A shared feast and open door, brightens nights and offers more. Sit and stay and take your part, bring your hunger and your heart.",

"<ROAR> Crowns may crumble into dust, but laughter shared is iron trust. Come forge your joy in flame and ale, and let it outlast any tale.",

"<ROAR> When doubt once whispered in the street, we answered warm and kept our feet. Choose the road where kindness leads, and walk with us in word and deeds.",

"<ROAR> Stone stands firm and so do we, returning often, faithfully. Leave your mark where friends endure, the deeper path is slow and sure.",

"<ROAR> Keep the fire against the cold, let stories rise and hands be bold. In leaner years and brighter days, we gather close and lift our praise.",

"<ROAR> The sky moves slow yet never strays, so shape your life in wandering ways. No rush required, no race to run, just steady hearts and shared sun.",

"<ROAR> Stand in silence, speak with care, lift another from despair. In balanced steps and voices strong, we find the place where we belong.",

"<ROAR> Ask and build and dare to try, let bright ideas multiply. Shared and tested, shaped by cheer, that is how we gather here.",

"<ROAR> Temper strength with open hand, let respect in power stand. When your voice rings true and deep, others wake from guarded sleep.",

"<ROAR> Trials passed and hardships crossed, forge a bond no war has lost. Through every chain and shadowed year, we choose to gather rather than fear.",

"<ROAR> Walk as kin upon this land, treat its soil with careful hand. It will carry you in turn, farther than pride alone could earn.",

"<ROAR> Community is quiet might, lifting each through darkest night. Stand upright and help another, here we stand as sister, brother.",

"<ROAR> Meaning grows where hearts entwine, shared endurance, shared design. Walk together, side by side, and find your strength within the pride.",

"<ROAR> Time is brief but joy is bright, claim it boldly in the night. Laugh out loud and stand up tall, let your voice be heard by all.",

"<ROAR> Speak your tale by ember glow, let it wander, let it grow. Around the fire your words will soar, and return to you once more.",

"<ROAR> When drums fall still and spirits hear, joy is what draws them near. Bring your cheer and let it pour, answer back with ROAR on ROAR.",

"<ROAR> Let old customs breathe and bend, welcome every newfound friend. In fresh voices, strong and clear, tradition lives and lingers here.",

"<ROAR> Across the tide and through the gale, shared grace will not grow pale. Walk with us through shifting lore, and find your home within the ROAR.",

"<ROAR> Coins may scatter, markets sway, but good renown will always stay. Build it bright in tale and deed, and let your echo travel speed.",

"<ROAR> Share your bread and pour the drink, that is stronger than you think. Feasts remembered, bonds well worn, that is how true names are born.",

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
