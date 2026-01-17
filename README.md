Here is a **Discord-clean, copy-paste-ready** version.
Uses bold headers, bullets, and spacing that render well in Discord without markdown weirdness.

---

**🦁 RoarGuild Addon**

**Version:** 1.2
**Author:** babunigaming
**Environment:** Vanilla / Turtle WoW 1.12 (Lua 5.0)

RoarGuild is a flavor-first action bar addon that makes your character feel alive.
It triggers emotes and movement-based rituals directly from gameplay—no macros, no rotation pollution.
Includes **GodBod**, a physical reminder system to keep the player alive too.

━━━━━━━━━━━━━━━━━━

**What It Does**

**RoarGuild**
• Uses real action bar presses as triggers
• Each watched slot belongs to an *instance* with its own cooldown and chance
• Emotes are no longer hardcoded
• You maintain a **master emote list**
• Each instance can draw from **multiple emotes**, chosen randomly
• Default emote is always **ROAR**
• Global **0.5% chance** to emote on any action for emergent flavor

**GodBod**
• Independent system
• Action bar presses trigger short exercise reminders
• Configurable chance and cooldown
• Outputs locally or to party/guild/chat depending on roll
• Designed to interrupt sedentary play without breaking immersion

The two systems share a hook but are otherwise isolated.

━━━━━━━━━━━━━━━━━━

**RoarGuild Slash Commands** (`/rogu`)

**Slot & Timing**
• `/rogu slotX <slot>` — assign slot to instance X
• `/rogu chanceX <0–100>` — trigger chance for instance X
• `/rogu timerX <seconds>` — cooldown for instance X

**Emote System**
• `/rogu emote <TOKEN>` — add emote to master list
• `/rogu emote list` — list all emotes with IDs
• `/rogu emoteX <id>` — add emote ID to instance X
• `/rogu emoteX -<id>` — remove emote ID
• `/rogu emoteX clear` — reset instance X to ROAR
• `/rogu emoteX list` — list emotes for instance X

**Control & Info**
• `/rogu watch` — print pressed slots
• `/rogu info` — full instance overview
• `/rogu reset` — clear all instances
• `/rogu on` / `/rogu off` — enable or disable
• `/rogu roar` — manually fire instance 1
• `/rogu rexp` — show rested XP (max 30 bubbles)

━━━━━━━━━━━━━━━━━━

**GodBod Slash Commands** (`/godbod`)

• `/godbod slot <slot>` — watch slot
• `/godbod unslot <slot>` — remove slot
• `/godbod clear` — clear all slots
• `/godbod watch` — debug slot presses
• `/godbod chance <0–100>` — trigger chance
• `/godbod cd <seconds>` — cooldown
• `/godbod on` / `/godbod off` — enable or disable
• `/godbod info` — show current settings

━━━━━━━━━━━━━━━━━━

**Quick Setup**

**RoarGuild**

1. `/rogu watch`
2. Press desired action bar slot
3. `/rogu slot1 <slot>`
4. `/rogu emote LAUGH`
5. `/rogu emote1 2`
6. `/rogu chance1 40`
7. `/rogu timer1 10`
8. `/rogu on`

**GodBod**

1. `/godbod slot <slot>`
2. `/godbod chance 80`
3. `/godbod cd 60`
4. `/godbod on`

━━━━━━━━━━━━━━━━━━

**Design Notes**
• No polling, no OnUpdate spam
• Fully event-driven through real gameplay
• Emotes are data-driven
• SavedVariables sanitized on load
• Default state is always safe and minimal

**Characters are not loadouts.**
**They are stories in motion.**
