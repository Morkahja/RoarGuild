-- RoarGuild + GodBod Combined v1.0
-- Vanilla / Turtle WoW 1.12
-- Lua 5.0-safe
-- SavedVariables: ROGUDB, WorkThatGodBodDB

-------------------------------------------------
-- DB Helpers
-------------------------------------------------
local function roarEnsureDB()
    if type(ROGUDB) ~= "table" then ROGUDB = {} end
    if type(ROGUDB.slots) ~= "table" then ROGUDB.slots = {} end
    return ROGUDB
end

local function roarEnsureEmotes()
    local db = roarEnsureDB()
    if type(db.emotes) ~= "table" then db.emotes = {} end
    -- default emote
    if #db.emotes == 0 then db.emotes[1] = { emote = "ROAR" } end
    return db.emotes
end

local function godEnsureDB()
    if type(WorkThatGodBodDB) ~= "table" then WorkThatGodBodDB = {} end
    if type(WorkThatGodBodDB.slots) ~= "table" then WorkThatGodBodDB.slots = {} end
    return WorkThatGodBodDB
end

-------------------------------------------------
-- Globals
-------------------------------------------------
local WATCH_SLOTS = {} -- [instance] = {slot, chance, cd, last}
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
    -- add remaining exercises as needed
}

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

local function getBattleEmotes()
    local emotes = roarEnsureEmotes()
    local t = {}
    for _, entry in pairs(emotes) do
        t[#t+1] = entry.emote
    end
    return t
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

-------------------------------------------------
-- RoarGuild Emotes Management
-------------------------------------------------
local function addRoarEmote(name)
    if not name or name == "" then return end
    local emotes = roarEnsureEmotes()
    for _, entry in pairs(emotes) do
        if entry.emote == name:upper() then return end
    end
    local nextID = 1
    for id in pairs(emotes) do
        if id >= nextID then nextID = id + 1 end
    end
    emotes[nextID] = { emote = name:upper() }
    roarChat("Added emote '"..name:upper().."' with ID "..nextID)
end

local function listRoarEmotes()
    local emotes = roarEnsureEmotes()
    roarChat("Emote list:")
    for id, entry in pairs(emotes) do
        roarChat("ID "..id..": "..entry.emote)
    end
end

local _roarLoaded = false
local function roarEnsureLoaded()
    if _roarLoaded then return end
    local db = roarEnsureDB()
    WATCH_SLOTS = db.slots or {}
    for _, cfg in pairs(WATCH_SLOTS) do
        if cfg.chance == nil then cfg.chance = 100 end
        if cfg.cd == nil then cfg.cd = 6 end
        if cfg.last == nil then cfg.last = 0 end
    end
    roarEnsureEmotes()
    if db.enabled ~= nil then ENABLED = db.enabled end
    _roarLoaded = true
end

local _godLoaded = false
local function godEnsureLoaded()
    if _godLoaded then return end
    local db = godEnsureDB()
    GOD_WATCH_SLOTS = db.slots or {}
    if db.cooldown then GOD_COOLDOWN = db.cooldown end
    if db.chance then GOD_CHANCE = db.chance end
    if db.enabled ~= nil then GOD_ENABLED = db.enabled end
    _godLoaded = true
end

-------------------------------------------------
-- GodBod Exercise Trigger
-------------------------------------------------
local function outputExercise(text)
    local roll = math.random(1,100)
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
    elseif roll >= 87 then
        SendChatMessage(text, "GUILD")
    else
        godChat(text)
    end
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
-- Hook UseAction
-------------------------------------------------
local _Orig_UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
    roarEnsureLoaded()
    godEnsureLoaded()
    local now = GetTime()

    if WATCH_MODE then roarChat("pressed slot "..tostring(slot)) end
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

-------------------------------------------------
-- Slash Commands /godbod
-------------------------------------------------
SLASH_GODBOD1 = "/godbod"
SlashCmdList["GODBOD"] = function(raw)
    godEnsureLoaded()
    local cmd, rest = split_cmd(raw)

    if cmd == "slot" then
        local n = tonumber(rest)
        if n and n>=1 then GOD_WATCH_SLOTS[n]=true; godChat("watching slot "..n) else godChat("usage: /godbod slot <n>") end
        return
    elseif cmd == "unslot" then
        local n = tonumber(rest)
        if n then GOD_WATCH_SLOTS[n]=nil; godChat("removed slot "..n) else godChat("usage: /godbod unslot <n>") end
        return
    elseif cmd == "clear" then GOD_WATCH_SLOTS={}; godEnsureDB().slots=GOD_WATCH_SLOTS; godChat("all slots cleared"); return
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
-- Save / Load
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event)
    if event=="PLAYER_LOGIN" then
        math.randomseed(math.floor(GetTime()*1000)); math.random()
        roarEnsureLoaded()
        godEnsureLoaded()
    elseif event=="PLAYER_LOGOUT" then
        local db = roarEnsureDB()
        db.slots = WATCH_SLOTS
        db.enabled = ENABLED
        db.emotes = roarEnsureEmotes()

        local goddb = godEnsureDB()
        goddb.slots = GOD_WATCH_SLOTS
        goddb.cooldown = GOD_COOLDOWN
        goddb.chance = GOD_CHANCE
        goddb.enabled = GOD_ENABLED
    end
end)
