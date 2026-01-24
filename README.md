**🦁 RoarGuild Addon**

**Version:** 1.3
**Author:** babunigaming
**Environment:** Vanilla / Turtle WoW 1.12 (Lua 5.0)

"RoarGuild adds a small, automatic chance for your character to roar during normal play, with optional systems to expand that behavior into a full expression addon."

RoarGuild is a flavor-first addon that makes your character feel alive.
It triggers emotes directly from gameplay — no macros, no rotation pollution.

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

━━━━━━━━━━━━━━━━━━

**Design Notes**
• No polling, no OnUpdate spam
• Fully event-driven through real gameplay
• Default state is always safe and minimal

**Characters are not loadouts.**
**They are stories in motion.**

More info on the discord: https://discord.gg/7J2QvXCMdE
