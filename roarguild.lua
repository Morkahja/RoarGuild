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
  "<ROAR> Friendly hearts and curious minds, we walk where living wonder shines, through ember glow and starlit air, each step reveals a world to share, when voices rise in chorus bright, we roar together into night.",
  "<ROAR> That rolling sound across the plain is laughter bright, not storm nor rain, it carries warmth from kinship true, from stories lived by me and you, come stand beside the hearthfire core, and add your voice to living roar.",
  "<ROAR> We hunt for stories rich and wide, where courage walks and dreams reside, no fleeting rush, no hollow claim, but living paths in shared flame, when tales awaken evermore, we crown them with a joyful roar.",
  "<ROAR> The roar gathers mugs held high, beneath the endless open sky, each triumph sung, each lesson shared, proves every soul is valued, cared, come take your place upon this floor, and live your truth within the roar.",
  "<ROAR> Casual steps and thunder cheer, shared old tales and friends held near, the wandering heart that seeks the flame, will find its echo in our name, by forge and song forevermore, you stand as kin within the roar.",
  "<ROAR> Quests and caverns blades and lore, shape the strength at spirit’s core, each crafted act and courage shown, becomes a light we call our own, when meaning blooms forevermore, it rises bright in living roar.",
  "<ROAR> If you sit for sky and song, where winding roads have called so long, where laughter warms and spirits rise, beneath the vast and knowing skies, then take your place beside the door, and share your flame within the roar.",
  "<ROAR> Inspire first and stand upright, let steady courage shape the light, each voice a spark, each soul a flame, no two alike, yet kin the same, when tankards ring forevermore, they echo strong in joyful roar.",
  "<ROAR> Explorers bright and wanderers wide, bring forth the dreams you hold inside, each crafted truth and tale you weave, becomes the strength in which we believe, lift high your voice forevermore, and crown the sky with fearless roar.",
  "<ROAR> Curiosity in common hand, shapes the fate of living land, shared stories born in ember glow, guide every step where dreamers go, if that same fire fills your core, come walk as kin within the roar.",
  "<ROAR> Steady footsteps shape the way, through silver night and golden day, each breath alive with truth and grace, each soul enriches time and space, when spirits rise forevermore, they shape the world with vibrant roar.",
  "<ROAR> For those who wander wide and free, through forest deep and endless sea, who read the stars and feel the ground, and know where truest joy is found, there waits a home forevermore, beside the fire of living roar.",
  "<ROAR> We chase the spark in fleeting air, and find its truth in moments shared, each laugh becomes a living flame, that crowns the bearer with their name, when meaning calls forevermore, we answer with resounding roar.",
  "<ROAR> Azeroth breathes with living flame, beyond all list and hollow claim, its valleys sing, its mountains soar, for those who walk with open core, step forth with pride forevermore, and join the world in joyful roar.",
  "<ROAR> From hushed twilight to rising cheer, shared voices bring each other near, through battle bright and peaceful rest, we shape the world through what is best, when kinship calls forevermore, we answer with united roar.",
  "<ROAR> Explorers, crafters, dreamers, kin, each journey starts where hearts begin, pull close the flame, share truth and light, that turns the dark to burning bright, for every soul forevermore, there waits a home within the roar.",
  "<ROAR> At your own pace the road unfolds, through living flame and truth retold, each step defines the path you claim, each breath ignites your inner flame, step through the light at open door, and shape your tale within the roar.",
  "<ROAR> Small triumphs rise to endless sky, where quiet strength and legends lie, each gentle act, each word sincere, becomes a truth that echoes clear, lift high your voice forevermore, and shake the world with fearless roar.",
  "<ROAR> Adventure shared grows fierce and bright, like forge made strong in glowing light, each oath and laugh and victory won, becomes a star beneath the sun, raise high your voice forevermore, and crown your tale with living roar.",
  "<ROAR> Raise your mug to roads untold, where living stories still unfold, each mile becomes a sacred flame, that crowns the bearer with their name, when hearts unite forevermore, the hills resound with joyful roar.",
  "<ROAR> Curiosity lights sacred flame, that calls each soul by truest name, let wonder guide your steady hand, across the sky and living land, speak forth with strength from deepest core, and join the song of endless roar.",
  "<ROAR> Look to the sky with fearless sight, where friendships blaze in living light, each shared breath and steady stride, builds the strength we hold inside, stand tall with heart forevermore, and walk as kin within the roar.",
  "<ROAR> Love the world in shining grace, each moment leaves its sacred trace, through clash and calm and endless sky, the spirit learns to rise and fly, let burning truth fill every core, and crown the stars with joyful roar.",
  "<ROAR> Gentle steps and steady flame, shape a path none else can claim, together strong and bright we stand, shaping fate with open hand, let shared strength rise forevermore, and echo wide in fearless roar.",
  "<ROAR> The journey earns its honored cheer, through every step we persevere, each laugh and trial shapes the soul, and draws us toward the shining whole, let voices rise forevermore, and shape the dawn with living roar.",
  "<ROAR> Wander wide with fearless heart, each step becomes a work of art, let spirit rise in golden blaze, that lights the path through endless days, speak forth with strength from deepest core, and crown the world with joyful roar.",
  "<ROAR> We chase the flame no time can bind, that lives within each seeking mind, when found it grows beyond all wall, and lifts the hearts and souls of all, let mountains sing forevermore, and shake the sky with fearless roar.",
  "<ROAR> Azeroth grows vast and bright, through those who walk with truth and light, each step inscribes a living flame, that crowns the bearer with their name, stand proud with heart forevermore, and shape the world with endless roar.",
  "<ROAR> From timid spark to blazing sun, each soul becomes what it has won, through courage bright and laughter strong, we find the place where we belong, let fearless truth fill every core, and rise as one in joyful roar.",
  "<ROAR> Thick as stout and bright as flame, imagination crowns your name, each presence adds its living light, that turns the dark to burning bright, step forth with strength forevermore, and claim your place within the roar.",
  "<ROAR> We roam with warmth and open hand, shaping fate across the land, each dream and hope and rising flame, becomes a star that bears your name, bring forth your strength from deepest core, and stand as kin within the roar.",
  "<ROAR> Hear the music in each quest, where living truth is manifest, let wonder guide your steady way, through silver night and golden day, lift up your voice forevermore, and crown the sky with vibrant roar.",
  "<ROAR> Sparks grow tall to endless sky, where courage lives and spirits fly, each victory bright, each lesson learned, becomes the fire forever burned, let shared strength rise forevermore, and shake the stars with fearless roar.",

  "<ROAR> Thoughtful steps on ancient stone, each path we walk becomes our own, through laughter bright and trials passed, we forge a bond that's built to last, when voices join forevermore, the world awakens in our roar.",
  "<ROAR> No hollow chase nor empty claim, but living hearts and rising flame, each moment shared, each story told, becomes a light more bright than gold, let kindred truth fill every core, and sing its strength through joyful roar.",
  "<ROAR> Respect and warmth in equal measure, shared discovery lasting treasure, each curious soul that steps inside, helps shape the strength of living pride, stand tall together evermore, and build your home within the roar.",
  "<ROAR> Give your tale to ember light, let it rise in shared delight, each spoken truth and laughter clear, becomes the song that draws us near, let memory bloom forevermore, and echo deep in living roar.",
  "<ROAR> A pride of hearts both kind and bold, where living warmth outshines the cold, each hand extended, freely given, becomes a bridge where souls have driven, step forward now and claim your lore, and stand as kin within the roar.",
  "<ROAR> From hush of dusk to dawn’s first flame, each breath renews the seeker’s claim, through gentle calm and victories bright, we shape the dark with living light, let fearless joy rise from your core, and crown the day with vibrant roar.",
  "<ROAR> Play with presence, deep and true, let Azeroth unfold for you, each moment lived, each friendship grown, becomes a strength you've always known, lift high your voice forevermore, and share its truth through living roar.",
  "<ROAR> Many paths and many feet, yet shared flame makes us complete, each voice distinct, each spirit strong, together we become the song, let unity rise forevermore, and thunder forth in joyful roar.",
  "<ROAR> Shared time forged in warmth and trust, rising bright from ash and dust, each gentle laugh, each knowing glance, becomes the spark of circumstance, let bonds endure forevermore, and shape the world through living roar.",
  "<ROAR> Curiosity and courage blend, where truest journeys never end, each question asked, each truth revealed, becomes the strength no fate can shield, step forward now through open door, and find your path within the roar.",
  "<ROAR> The world rewards the open heart, that dares to walk and take its part, each careful step, each spirit wide, becomes the strength of living pride, let wonder rise forevermore, and crown your tale with joyful roar.",
  "<ROAR> Walk together, steady stride, where living strength and warmth reside, each shared mile and spoken name, becomes the spark of rising flame, let courage carry evermore, and sing aloud through vibrant roar.",
  "<ROAR> Above all else we choose the flame, the joy that crowns the journey’s name, each breath alive with truth and grace, becomes a gift no time can erase, let living wonder fill your core, and shape the stars with endless roar.",
  "<ROAR> Hearts alight with steady glow, guide the paths where dreamers go, each voice a thread in woven fire, rising ever bright and higher, step inside forevermore, and stand as kin within the roar.",
  "<ROAR> Where stories meet and spirits rise, beneath the vast eternal skies, each shared truth and laughter clear, becomes the strength that draws us near, let every soul forevermore, find warmth and home within the roar.",
  "<ROAR> The forge burns bright in every chest, where curiosity finds its rest, each dream pursued, each friendship sealed, becomes the truth the world revealed, lift high your voice forevermore, and crown the night with vibrant roar.",
  "<ROAR> Wonder lives in those who seek, in quiet strong and bold and meek, each careful step and open mind, reveals the strength in humankind, let living joy rise from your core, and walk as kin within the roar.",
  "<ROAR> No two journeys walk the same, yet all are bound by shared flame, each path unique, each spirit bright, together form a greater light, let unity bloom forevermore, and sing as one through joyful roar.",
  "<ROAR> The fire we tend is freely shared, by every soul who knows and cared, each breath and word, each living choice, becomes the strength in every voice, let kindred truth rise from your core, and shape the world through living roar.",
  "<ROAR> Across the hills and endless plains, where living wonder still remains, each step becomes a sacred thread, by which new stories shall be spread, lift high your voice forevermore, and crown the land with vibrant roar.",
  "<ROAR> Presence strong and spirits free, shape the paths of destiny, each laugh and bond and moment shared, becomes the proof that we have dared, step forward now forevermore, and join your kin within the roar.",
  "<ROAR> Through torchlit halls and open skies, the truth of shared adventure lies, each voice that joins, each heart that stays, becomes the light of future days, let fearless joy fill every core, and echo wide through living roar.",
  "<ROAR> Courage blooms where trust is grown, in shared paths we are not alone, each breath aligned, each vision shared, becomes the truth that we have dared, stand tall together evermore, and crown the world with vibrant roar.",
  "<ROAR> A living world beneath our feet, made rich by every soul we meet, each kindness given, freely sown, becomes a strength the heart has known, let shared warmth rise forevermore, and sing aloud through joyful roar.",
  "<ROAR> Where gentle strength and laughter meet, new legends rise on steady feet, each moment lived with open eyes, becomes the truth no time denies, lift high your voice forevermore, and stand as kin within the roar.",
  "<ROAR> The road expands with every friend, where living stories never end, each hand extended, freely given, becomes the truth by which we’ve driven, step forward now through open door, and shape your fate within the roar.",
  "<ROAR> No measured worth nor hollow scale, but living truth in every tale, each breath alive, each spirit strong, becomes the place where we belong, let fearless joy fill every core, and crown the sky with vibrant roar.",
  "<ROAR> Ember light and steady flame, shape the strength behind each name, each tale retold, each bond renewed, becomes the path by which we grew, let shared wonder rise forevermore, and sing aloud through joyful roar.",
  "<ROAR> The stars above and earth below, bear witness to the paths we go, each step aligned with inner flame, becomes the truth no fear can claim, lift high your voice forevermore, and shape the world with vibrant roar.",
  "<ROAR> Living presence, warm and clear, shapes the bonds that draw us near, each breath and word and moment shared, becomes the strength by which we’ve dared, stand proud together evermore, and walk as kin within the roar.",
  "<ROAR> Where laughter rings and stories live, each soul discovers what they give, each moment shaped by truth and grace, becomes a light no dark can erase, let living joy rise from your core, and crown the dawn with endless roar.",
  "<ROAR> The hearth remains with steady flame, calling softly every name, each voice that joins adds living light, that turns the dark to burning bright, step through the warmth forevermore, and find your place within the roar.",
  "<ROAR> Together strong in living flame, each soul becomes more than a name, each shared breath and vision clear, becomes the strength that draws us near, let unity rise forevermore, and thunder forth in joyful roar.",

  "<ROAR> Where firelight dances on lifted faces, shared time fills the quiet spaces, each gentle word and knowing grin, becomes the strength that grows within, step toward the glow forevermore, and find your voice within the roar.",
  "<ROAR> The open road beneath our feet, turns every stranger kin we meet, each mile reveals what hearts can be, when walked in shared sincerity, let every breath forevermore, resound with truth through vibrant roar.",
  "<ROAR> Curiosity lights hidden doors, revealing worlds not seen before, each question asked, each answer earned, becomes a flame forever burned, lift high your voice from deepest core, and shape the night with fearless roar.",
  "<ROAR> Beneath the sky both vast and bright, we find our strength in shared light, each step aligned, each spirit free, becomes the path of destiny, let living warmth rise evermore, and sing its truth through joyful roar.",
  "<ROAR> Through whispered woods and mountain air, adventure waits for those who dare, each breath alive, each vision wide, becomes the strength of living pride, step forward now forevermore, and stand as kin within the roar.",
  "<ROAR> No soul alone upon this way, for shared flame lights each passing day, each outstretched hand and offered place, becomes the gift no time can erase, let unity rise forevermore, and crown the world with vibrant roar.",
  "<ROAR> Where tankards ring and laughter flows, the truest strength among us grows, each moment shared in open cheer, becomes the bond that draws us near, lift high your voice forevermore, and echo strong through living roar.",
  "<ROAR> The path unfolds for those who seek, in quiet strong and bold and meek, each truth discovered, freely shared, becomes the strength for which we dared, step through the flame forevermore, and shape your fate within the roar.",
  "<ROAR> Azeroth breathes in living flame, and calls each soul by truest name, each hill and hall, each sky and sea, reveals what we are meant to be, let fearless joy rise from your core, and join its song in vibrant roar.",
  "<ROAR> Shared presence turns the dark to gold, where living stories are retold, each voice distinct, each spirit bright, becomes a star within the night, stand tall together evermore, and shine as one in joyful roar.",
  "<ROAR> From quiet dawn to ember night, we walk as bearers of shared light, each careful step, each dream pursued, becomes the truth by which we grew, lift high your voice forevermore, and crown your tale with living roar.",
  "<ROAR> Curiosity the truest guide, reveals the strength we hold inside, each truth revealed, each question born, becomes the spark of brighter morn, step forward now forevermore, and stand as kin within the roar.",
  "<ROAR> The hearth remains with steady flame, welcoming each seeking name, each soul that joins adds living light, that turns the dark to burning bright, let shared warmth rise forevermore, and shape the world through joyful roar.",
  "<ROAR> Where laughter lives and courage grows, the truest path each spirit knows, each moment lived in open truth, renews the strength of endless youth, lift high your voice forevermore, and sing as one through vibrant roar.",
  "<ROAR> Beneath the forge of living days, shared presence lights uncounted ways, each act of care, each offered hand, becomes the strength on which we stand, step toward the flame forevermore, and claim your place within the roar.",
  "<ROAR> Each voice that joins expands the flame, and crowns the bearer with their name, each path once walked becomes more wide, when shared among the living pride, let unity bloom forevermore, and thunder forth in joyful roar.",
  "<ROAR> The living world unfolds for those, whose hearts remain awake and close, each breath aligned with truth and grace, becomes the strength no time can erase, lift high your voice forevermore, and shape the dawn with vibrant roar.",
  "<ROAR> Through shared discovery and trust, new legends rise from ash and dust, each dream pursued, each truth revealed, becomes the fate no fear can shield, step forward now forevermore, and stand as kin within the roar.",
  "<ROAR> Where steady hearts and kindred meet, new strength is born on willing feet, each gentle act and honest voice, becomes the proof of conscious choice, let shared truth rise forevermore, and echo wide through living roar.",
  "<ROAR> Azeroth lives in every breath, untouched by hollow scale or death, each moment shaped by presence true, reveals the world forever new, lift high your voice from deepest core, and crown its truth with vibrant roar.",
  "<ROAR> The warmth we share becomes our guide, through endless paths both far and wide, each hand in hand, each spirit known, becomes the strength we've always grown, step toward the flame forevermore, and find your kin within the roar.",
  "<ROAR> Curiosity unlocks the sky, where endless truths and wonders lie, each soul who dares to look and see, becomes what they were meant to be, let fearless joy rise from your core, and sing its truth through vibrant roar.",
  "<ROAR> Each moment shared becomes a spark, that lights the way through deepest dark, each voice aligned in honest flame, becomes the truth beyond all name, stand proud together evermore, and shape the world through joyful roar.",
  "<ROAR> Where presence lives and hearts align, shared existence grows divine, each breath and word and offered hand, becomes the strength of living land, lift high your voice forevermore, and thunder forth in vibrant roar.",
  "<ROAR> The forge of time reveals the soul, made stronger still through shared whole, each trial faced, each truth embraced, becomes the gift no fear erased, step forward now forevermore, and stand as kin within the roar.",
  "<ROAR> Shared laughter shapes eternal flame, beyond all measure, scale, or name, each moment lived with open heart, becomes a work of living art, let fearless joy rise from your core, and crown the stars with vibrant roar.",
  "<ROAR> Each new voice adds rising light, that turns the dark to burning bright, each spirit joined in common flame, expands the truth beyond all name, stand tall together evermore, and sing as one through joyful roar.",
  "<ROAR> The living flame calls all who hear, through courage strong and vision clear, each breath alive, each soul awake, becomes the path no fear can break, lift high your voice forevermore, and shape the dawn through vibrant roar.",
  "<ROAR> Through shared steps and patient sight, new strength emerges into light, each act of care and truth revealed, becomes the bond no time can yield, step toward the warmth forevermore, and find your place within the roar.",
  "<ROAR> Where gentle strength and presence meet, the living world becomes complete, each offered truth, each spirit free, becomes the shape of destiny, let shared wonder rise forevermore, and echo strong through joyful roar.",
  "<ROAR> Azeroth unfolds in those, whose hearts remain both brave and close, each breath aligned with living flame, becomes the truth beyond all name, lift high your voice forevermore, and crown its path with vibrant roar.",
  "<ROAR> The fire we share cannot grow dim, for every soul strengthens its hymn, each voice unique, each presence bright, expands the living flame of light, step forward now forevermore, and stand as kin within the roar.",
  "<ROAR> Together bound in living flame, beyond all doubt, beyond all name, each breath and truth and shared embrace, becomes the strength no time can erase, let unity rise forevermore, and thunder forth in endless roar.",

  "<ROAR> The ember waits in every soul, to rise and join the greater whole, each voice a spark, each heart a flame, together stronger than a name, step through the glow forevermore, and stand united in the roar.",
  "<ROAR> Where steady boots on ancient stone, remind us none now walk alone, each shared mile and lifted cheer, becomes the truth that draws us near, let living warmth rise from your core, and shape the dawn with vibrant roar.",
  "<ROAR> Curiosity the lantern bright, reveals new paths in gentle light, each question asked, each truth made clear, becomes the bond that brings us near, lift high your voice forevermore, and crown the world with joyful roar.",
  "<ROAR> Beneath the sky both fierce and kind, we leave no seeking soul behind, each hand extended, freely given, becomes the proof of purpose driven, step forward now through open door, and find your home within the roar.",
  "<ROAR> The forge of friendship burns so true, in every shared breath me and you, each moment lived in honest flame, becomes the strength beyond all name, let fearless joy rise evermore, and echo wide through living roar.",
  "<ROAR> Azeroth sings through those who hear, its living truth both strong and clear, each step aligned with open heart, becomes a work of sacred art, lift high your voice from deepest core, and join its song in vibrant roar.",
  "<ROAR> No silent spark nor hidden flame, for every soul deserves its name, each story told and laughter shared, becomes the strength for which we dared, stand tall together evermore, and rise as one in joyful roar.",
  "<ROAR> The road expands with every friend, revealing paths that never end, each presence adds its living thread, to weave the truth where all are led, step through the light forevermore, and shape your fate within the roar.",
  "<ROAR> Where courage walks and kindness stays, new strength is born in countless ways, each gentle act, each offered hand, becomes the truth on which we stand, let unity bloom forevermore, and thunder forth in vibrant roar.",
  "<ROAR> The living flame in every chest, reveals the path that leads to best, each breath aligned, each spirit free, becomes the shape of destiny, lift high your voice forevermore, and crown your tale with living roar.",
  "<ROAR> Through patient steps and watchful eyes, shared truth beneath eternal skies, each lesson learned, each bond renewed, becomes the path by which we grew, step toward the warmth forevermore, and find your kin within the roar.",
  "<ROAR> The hearthfire glows for those who seek, the strong, the bold, the wise, the meek, each voice that joins expands its light, and turns the dark to burning bright, let shared wonder rise from your core, and shape the stars with vibrant roar.",
  "<ROAR> Azeroth lives in every breath, beyond all hollow scale or death, each moment shaped by presence true, becomes the strength that carries through, lift high your voice forevermore, and sing its truth through joyful roar.",
  "<ROAR> Each shared path builds living flame, beyond all doubt, beyond all name, each careful step and vision clear, becomes the truth that draws us near, stand proud together evermore, and walk as kin within the roar.",
  "<ROAR> Where gentle laughter meets bold might, new legends rise in shared light, each moment lived with open eyes, becomes the truth that never dies, let fearless joy rise from your core, and crown the dawn with vibrant roar.",
  "<ROAR> Curiosity unlocks the way, revealing more with each new day, each soul who dares to walk and see, becomes what they were meant to be, step through the flame forevermore, and stand united in the roar.",
  "<ROAR> The warmth of shared discovery, reveals the strength of unity, each breath aligned, each spirit bright, becomes a star within the night, lift high your voice forevermore, and shape the world with joyful roar.",
  "<ROAR> The living world awaits your tread, where shared truth walks where you are led, each act of care, each offered grace, becomes the light no dark can erase, step toward the flame forevermore, and claim your place within the roar.",
  "<ROAR> No voice too soft, no flame too small, for shared presence strengthens all, each truth revealed, each bond made strong, becomes the place where we belong, let unity rise forevermore, and thunder forth in vibrant roar.",
  "<ROAR> Azeroth unfolds in those, whose hearts remain awake and close, each breath alive with living flame, becomes the truth beyond all name, lift high your voice from deepest core, and crown its path with joyful roar.",
  "<ROAR> Where kindred spirits freely stand, they shape the fate of living land, each shared dream and offered hand, becomes the truth on which we stand, step forward now forevermore, and stand as kin within the roar.",
  "<ROAR> The fire we share forever grows, in every heart that truly knows, each breath aligned with open grace, becomes the strength no time can erase, let fearless joy rise from your core, and echo wide through vibrant roar.",
  "<ROAR> Through shared time and steady flame, each soul becomes more than a name, each moment lived with presence clear, becomes the truth that draws us near, lift high your voice forevermore, and crown the night with joyful roar.",
  "<ROAR> Where stories meet and futures rise, shared truth lives beneath these skies, each bond formed in honest flame, becomes the strength beyond all name, step through the glow forevermore, and shape your fate within the roar.",
  "<ROAR> The path of shared discovery, reveals the strength of unity, each careful breath, each living choice, becomes the power in your voice, let living wonder rise evermore, and sing aloud through vibrant roar.",
  "<ROAR> Azeroth calls with gentle flame, inviting each to stake their claim, each soul who walks with open sight, becomes a bearer of its light, lift high your voice forevermore, and crown its truth with joyful roar.",
  "<ROAR> Where presence lives and courage stays, new legends rise in countless ways, each act of care, each offered hand, becomes the strength on which we stand, step forward now forevermore, and stand united in the roar.",
  "<ROAR> The ember grows where truth is shared, by every soul who walks prepared, each breath alive, each spirit strong, becomes the place where we belong, let unity bloom forevermore, and thunder forth in vibrant roar.",
  "<ROAR> Each shared laugh and knowing glance, strengthens fate and circumstance, each living truth, each moment bright, becomes a star within the night, lift high your voice forevermore, and sing its truth through joyful roar.",
  "<ROAR> The flame of shared existence grows, in every heart that truly knows, each careful step, each offered place, becomes the strength no time can erase, step toward the warmth forevermore, and find your kin within the roar.",
  "<ROAR> Azeroth breathes through those who care, who walk its lands with hearts laid bare, each moment lived with truth and flame, becomes the strength beyond all name, lift high your voice forevermore, and crown its path with vibrant roar.",
  "<ROAR> Through shared presence and steady flame, each soul becomes more than a name, each act of care and vision clear, becomes the truth that draws us near, stand tall together evermore, and walk as kin within the roar.",
  "<ROAR> United now in living flame, beyond all doubt, beyond all name, each breath aligned, each spirit free, becomes the shape of destiny, let fearless joy rise from your core, and thunder forth in endless roar.",

  "<ROAR> The dawn arrives on steady feet, where shared horizons always meet, each golden ray, each breath we take, becomes the path new souls awake, lift high your voice forevermore, and greet the day with vibrant roar.",
  "<ROAR> Where campfires glow and stories bloom, no spirit stands in silent gloom, each laugh that rings, each hand held near, becomes the truth that draws us near, step through the warmth forevermore, and find your kin within the roar.",
  "<ROAR> Curiosity shapes living flame, revealing truths beyond all name, each question asked with open sight, becomes a bearer of shared light, let living wonder fill your core, and crown your path with joyful roar.",
  "<ROAR> The wind that moves through ancient trees, still carries songs of destinies, each voice that joins its endless hymn, ensures the living flame won't dim, stand proud together evermore, and sing as one in vibrant roar.",
  "<ROAR> Each journey walked with honest heart, becomes a living work of art, each step aligned with shared delight, turns shadowed roads to paths of light, lift high your voice forevermore, and shape the world with fearless roar.",
  "<ROAR> Azeroth calls to those who hear, with promise bright and vision clear, each soul who walks its living land, helps shape its fate by heart and hand, step forward now through open door, and stand united in the roar.",
  "<ROAR> Through forge and field and starlit sky, shared spirits lift each other high, each breath alive with purpose true, becomes the strength that carries through, let unity rise forevermore, and thunder forth in vibrant roar.",
  "<ROAR> No path too long, no night too deep, when kindred souls their vigil keep, each moment shared in honest flame, becomes the truth beyond all name, lift high your voice from deepest core, and sing aloud through joyful roar.",
  "<ROAR> Where shared discovery lights the way, new strength is born with every day, each act of care, each offered hand, becomes the truth on which we stand, step toward the flame forevermore, and find your place within the roar.",
  "<ROAR> The living flame in every chest, reveals the truth within the quest, each breath aligned with open grace, becomes the strength no time erase, stand tall together evermore, and crown the sky with vibrant roar.",
  "<ROAR> Curiosity unlocks new sight, revealing strength in shared light, each dream pursued, each truth revealed, becomes the fate no fear can shield, lift high your voice forevermore, and shape the dawn through joyful roar.",
  "<ROAR> Beneath the sky both fierce and fair, shared presence lifts all who dare, each spirit joined, each voice made strong, becomes the place where we belong, step through the warmth forevermore, and stand as kin within the roar.",
  "<ROAR> Azeroth breathes through those who roam, who turn shared presence into home, each careful step, each vision wide, becomes the strength of living pride, let fearless joy rise from your core, and echo wide through vibrant roar.",
  "<ROAR> Where hearthfires burn and tankards rise, shared truth lives beneath the skies, each story told, each laugh sincere, becomes the bond that draws us near, lift high your voice forevermore, and sing its truth through joyful roar.",
  "<ROAR> Each soul that joins expands the flame, beyond all doubt, beyond all name, each breath aligned with living grace, becomes the truth no time erase, step forward now through open door, and shape your fate within the roar.",
  "<ROAR> Through shared time and steady flame, each spirit grows beyond its name, each moment lived with purpose clear, becomes the truth that draws us near, stand proud together evermore, and thunder forth in vibrant roar.",
  "<ROAR> The road ahead unfolds in light, for those who walk with open sight, each act of care, each offered place, becomes the strength no dark erase, lift high your voice forevermore, and crown the world with joyful roar.",
  "<ROAR> Curiosity the guiding star, reveals how strong together we are, each soul aligned in shared delight, becomes a bearer of the light, step through the flame forevermore, and stand united in the roar.",
  "<ROAR> Azeroth lives in breath and bone, yet grows far stronger not alone, each hand extended, freely given, becomes the proof of purpose driven, let unity bloom forevermore, and sing aloud through vibrant roar.",
  "<ROAR> Each shared laugh and knowing gaze, shapes the truth of living days, each careful step, each vision bright, becomes a star within the night, lift high your voice forevermore, and crown your tale with joyful roar.",
  "<ROAR> Where gentle strength and boldness meet, new legends rise on willing feet, each breath alive, each spirit free, becomes the shape of destiny, step toward the warmth forevermore, and find your kin within the roar.",
  "<ROAR> The living world responds to those, whose hearts remain awake and close, each truth revealed, each bond made strong, becomes the place where we belong, stand tall together evermore, and echo wide through vibrant roar.",
  "<ROAR> Azeroth unfolds its endless flame, for every soul that stakes its claim, each breath aligned with purpose true, becomes the strength that carries through, lift high your voice from deepest core, and shape the sky with fearless roar.",
  "<ROAR> Through shared discovery and care, new strength emerges everywhere, each moment lived with presence clear, becomes the truth that draws us near, step forward now forevermore, and stand united in the roar.",
  "<ROAR> The ember grows in every heart, that dares to walk and take its part, each dream pursued, each truth made known, becomes a strength we call our own, let fearless joy rise evermore, and sing its truth through vibrant roar.",
  "<ROAR> Where tankards meet and firelight gleams, shared presence shapes our living dreams, each voice aligned in honest flame, becomes the truth beyond all name, lift high your voice forevermore, and crown the dawn with joyful roar.",
  "<ROAR> Azeroth breathes in every stride, and walks beside the living pride, each breath alive with purpose clear, becomes the strength that draws us near, step through the warmth forevermore, and find your place within the roar.",
  "<ROAR> Curiosity lights hidden ways, revealing strength in countless days, each soul who dares to walk and see, becomes what they were meant to be, let unity bloom forevermore, and thunder forth in vibrant roar.",
  "<ROAR> The forge of shared existence burns, with every truth the spirit learns, each moment shaped by honest flame, becomes the strength beyond all name, lift high your voice forevermore, and sing aloud through joyful roar.",
  "<ROAR> Each voice that joins expands the whole, strengthening the living soul, each breath aligned with open grace, becomes the truth no time erase, stand proud together evermore, and shape the world with vibrant roar.",
  "<ROAR> Azeroth calls with steady flame, inviting each to stake their claim, each careful step, each vision wide, becomes the strength of living pride, lift high your voice forevermore, and crown its truth with joyful roar.",
  "<ROAR> Through shared presence and open heart, we shape the whole from every part, each act of care, each truth revealed, becomes the fate no fear can shield, step forward now forevermore, and stand united in the roar.",
  "<ROAR> United still in living flame, beyond all doubt, beyond all name, each breath aligned, each spirit free, becomes the shape of destiny, let fearless joy rise from your core, and thunder forth in endless roar.",

  "<ROAR> Boots on stone and spirits soar, come walk with us and roar once more.",
  "<ROAR> Fire is warm and hearts are strong, come find the place where you belong.",
  "<ROAR> Tales await beyond the door, step inside and join the roar.",
  "<ROAR> Wander wide and stand up tall, shared adventure calls us all.",
  "<ROAR> Tankards raised and laughter bright, come join our path into the night.",
  "<ROAR> Sparks awake where dreamers stand, come shape the world with steady hand.",
  "<ROAR> Stories grow where friends unite, come share the flame and living light.",
  "<ROAR> Roads are long but never lone, come make this roaring pride your own.",
  "<ROAR> Hear the call and feel it true, there is a place here just for you.",
  "<ROAR> Steps in rhythm, hearts aligned, come leave the silent world behind.",
  "<ROAR> Flame and friendship guide the way, come live the story day by day.",
  "<ROAR> Stand with us where legends start, bring your voice and bring your heart.",
  "<ROAR> Every spark can light the sky, come join the roar and rise up high.",
  "<ROAR> Forge your tale in ember glow, come with us and let it grow.",
  "<ROAR> Shared steps make the spirit strong, come walk with those who journey long.",
  "<ROAR> Lift your eyes and take your place, come share the warmth and shared embrace.",
  "<ROAR> Paths unfold where dreamers tread, come wake the fire that lies ahead.",
  "<ROAR> Living stories call your name, come stand with us inside the flame.",
  "<ROAR> No voice too small to shape the sky, come roar with us and rise up high.",
  "<ROAR> Fire awaits where hearts are true, come share the path and see it through.",
  "<ROAR> From silent spark to thunder cry, come join the pride that will not die.",
  "<ROAR> Kindred souls and steady flame, come help the roar become your name.",
  "<ROAR> Adventure waits in every breath, come walk beyond the edge of death.",
  "<ROAR> Stand with those who dare explore, come shape your tale inside the roar.",
  "<ROAR> Through storm and sun our voices blend, come walk beside us, friend to friend.",
  "<ROAR> Shared flame burns forever bright, come join our pride and claim your light.",
  "<ROAR> Strength is born where spirits meet, come walk with roaring, steady feet.",
  "<ROAR> Every path can lead you here, come join the pride and cast off fear.",
  "<ROAR> Let your voice become the flame, come rise with us and stake your name.",
  "<ROAR> The world expands when hearts unite, come share the roar and shared light.",
  "<ROAR> Find the fire you carry deep, come join the pride that souls still keep.",
  "<ROAR> Walk with those who dare to dream, come join the roar and shape the seen.",
  "<ROAR> Where courage lives and dreamers soar, come stand with us and roar once more.",

  "<ROAR> We walk and we see what worlds can be, come join our pride and roam with glee.",
  "<ROAR> We climb and explore, then roar even more, come join our guild and open the door.",
  "<ROAR> We laugh and we fight in shared living light, come join our pride and burn ever bright.",
  "<ROAR> We wander and sing through every new thing, come join our pride and let your voice ring.",
  "<ROAR> We journey afar beneath every star, come join our pride just as you are.",
  "<ROAR> We gather and grow, let curiosity flow, come join ROAR and let your spark show.",
  "<ROAR> We travel as one beneath moon and sun, come join our pride, your tale’s begun.",
  "<ROAR> We dream and we dare with kinship to share, come join our guild, your flame is there.",
  "<ROAR> We stand and we rise with fire in our eyes, come join our pride where courage lies.",
  "<ROAR> We roam and we find new truths of the mind, come join our pride and leave none behind.",
  "<ROAR> We share and we care, true strength laid bare, come join our guild, your path is there.",
  "<ROAR> We venture and see what more we can be, come join our pride and roam wild and free.",
  "<ROAR> We kindle the flame and strengthen the name, come join our pride and do the same.",
  "<ROAR> We stride and we grow with hearts all aglow, come join ROAR and let your fire show.",
  "<ROAR> We laugh through the night till dawn brings new light, come join our pride and shine ever bright.",
  "<ROAR> We explore and we learn at every new turn, come join our pride, let your spirit burn.",
  "<ROAR> We wander and meet where brave hearts greet, come join our guild and feel complete.",
  "<ROAR> We rise and we stand across every land, come join our pride and lend your hand.",
  "<ROAR> We live and we play in our own steady way, come join ROAR and brighten the day.",
  "<ROAR> We forge and create the shape of our fate, come join our pride before it’s too late.",
  "<ROAR> We seek and we find new worlds of the mind, come join our pride and be unconfined.",
  "<ROAR> We sing and we cheer for those gathered here, come join our pride and draw ever near.",
  "<ROAR> We blaze and we glow with all that we know, come join ROAR and help it grow.",
  "<ROAR> We roam and we thrive, truly alive, come join our pride and feel the drive.",
  "<ROAR> We gather and stand a proud living band, come join our guild and shape the land.",
  "<ROAR> We breathe and we see what strength there can be, come join our pride and roam wild and free.",
  "<ROAR> We rise and unite in shared roaring light, come join our pride and shine ever bright.",
  "<ROAR> We walk and we share a presence so rare, come join our guild, your voice belongs there.",
  "<ROAR> We journey and learn with each flame that burns, come join ROAR at every turn.",
  "<ROAR> We wander and grow with hearts all aglow, come join our pride and let it show.",
  "<ROAR> We live and we explore what lies at the core, come join our pride and roar evermore.",
  "<ROAR> We gather and sing of everything, come join our pride and let joy ring.",
  "<ROAR> We stride and we soar becoming much more, come join our pride and roar evermore.",

  "<ROAR> We stroll and explore, then laugh and roar, step on our path and wander more.",
  "<ROAR> No need to race, just find your pace, your place awaits within this space.",
  "<ROAR> We quest, we cheer, the road is clear, your voice belongs among us here.",
  "<ROAR> Through hill and shore, we seek the lore, let your spark join the roar once more.",
  "<ROAR> We take it slow, let stories grow, your flame will find its steady flow.",
  "<ROAR> From dawn to night, the vibes feel right, your presence turns the dark to light.",
  "<ROAR> We roam the land, hand in hand, your strength will help this pride expand.",
  "<ROAR> No hollow chase, just shared embrace, your step completes this living place.",
  "<ROAR> We laugh, we cheer, good friends are near, your story strengthens what lives here.",
  "<ROAR> The world feels wide when shared inside, your breath enriches all beside.",
  "<ROAR> We walk and see what worlds can be, your spark unlocks new destiny.",
  "<ROAR> We climb and explore, then roar even more, your echo strengthens at the core.",
  "<ROAR> We laugh and we rise beneath open skies, your courage helps our spirit rise.",
  "<ROAR> We wander and sing through everything, your living truth makes voices ring.",
  "<ROAR> We journey afar beneath every star, your light reveals how strong we are.",
  "<ROAR> We gather and grow, let curiosity flow, your presence helps the fire glow.",
  "<ROAR> We travel as one beneath moon and sun, your step affirms what we've begun.",
  "<ROAR> We dream and we dare with stories to share, your voice becomes the answer there.",
  "<ROAR> We stand and we rise with fire in our eyes, your strength ensures the flame survives.",
  "<ROAR> We roam and we find new truths of the mind, your vision leaves no soul behind.",
  "<ROAR> We share and we care with warmth laid bare, your breath brings deeper meaning there.",
  "<ROAR> We venture and see what more we can be, your spark expands reality.",
  "<ROAR> We kindle the flame and strengthen the name, your spirit feeds the living flame.",
  "<ROAR> We stride and we grow with hearts all aglow, your will ensures the embers grow.",
  "<ROAR> We laugh through the night till dawn brings new light, your presence makes the future bright.",
  "<ROAR> We explore and we learn at every turn, your insight gives the flame to burn.",
  "<ROAR> We wander and meet where brave hearts greet, your step makes this circle complete.",
  "<ROAR> We rise and we stand across every land, your courage shapes what we command.",
  "<ROAR> We live and we play in our own steady way, your breath gives meaning to the day.",
  "<ROAR> We forge and create the shape of our fate, your hand helps open every gate.",
  "<ROAR> We seek and we find what lives in the mind, your truth reshapes what we may find.",
  "<ROAR> We sing and we cheer for those gathered here, your voice makes distant futures near.",
  "<ROAR> We blaze and we glow with all that we know, your presence helps the fire grow."

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
