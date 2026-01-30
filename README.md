**🦁 RoarGuild Addon**

**Version:** 1.32
**Author:** babunigaming
**Environment:** Vanilla / Turtle WoW 1.12 (Lua 5.0)

RoarGuild adds a small, automatic chance for your character to express themselves through emotes during normal play, with optional systems that expand this into a fully configurable expression addon.

RoarGuild is flavor-first.
It reacts to *what you actually do* in combat and play — no macros, no rotation pollution, no artificial timers.

━━━━━━━━━━━━━━━━━━

**What It Does**

**RoarGuild**

* Hooks directly into real action bar presses
* Uses *instances* bound to specific action bar slots
* Each instance has its own cooldown, chance, and emote pool
* Emotes are fully configurable and no longer hardcoded
* A shared **master emote list** is maintained per account
* Each instance can randomly pick from multiple assigned emotes
* Default and guaranteed fallback emote is **ROAR**
* Includes an independent **global fallback trigger**

  * Default: **0.5% chance** on any action bar press
  * Creates rare, emergent moments even outside configured slots
* Optional reminder system if you have not roared in a while
* Profile-based configuration per character (Option C profiles)

━━━━━━━━━━━━━━━━━━

**Design Philosophy**

RoarGuild is not about optimization.
It is about *presence*.

It treats your character as a living participant in the world, not a silent executor of rotations. Emotes happen because you act — not because a timer fired.

The system is intentionally lightweight, transparent, and predictable where it matters, and slightly chaotic where it adds charm.

━━━━━━━━━━━━━━━━━━

**RoarGuild Slash Commands** (`/rogu`)

**Slot & Timing**

* `/rogu slotX <slot>` — assign action bar slot to instance X
* `/rogu chanceX <0–100>` — trigger chance for instance X
* `/rogu timerX <seconds>` — cooldown for instance X
* `/rogu resetcd` — reset all instance and fallback cooldown timers

**Emote System**

* `/rogu emote <TOKEN>` — add emote to the master emote list
* `/rogu emote list` — list all emotes with IDs
* `/rogu emoteX <id>` — add emote ID to instance X
* `/rogu emoteX -<id>` — remove emote ID from instance X
* `/rogu emoteX clear` — reset instance X to default ROAR
* `/rogu emoteX list` — list emotes assigned to instance X

**Control & Info**

* `/rogu watch` — print pressed action bar slot numbers
* `/rogu info` — detailed overview of all instances and fallback
* `/rogu reset` — remove all configured instances
* `/rogu on` / `/rogu off` — enable or disable RoarGuild
* `/rogu roar` — manually trigger instance 1
* `/rogu rexp` — display rested XP in bubbles (max 30)
* `/rogu invite` — send a random guild recruitment message to General

━━━━━━━━━━━━━━━━━━

**Quick Setup Example**

1. `/rogu watch`
2. Press the action bar slot you want to react to
3. `/rogu slot1 <slot>`
4. `/rogu emote LAUGH`
5. `/rogu emote1 2`
6. `/rogu chance1 40`
7. `/rogu timer1 10`
8. `/rogu on`

Result:
A 40% chance to LAUGH when that action is used, with a 10-second cooldown.

━━━━━━━━━━━━━━━━━━

**Profiles & Saved Variables**

* Each character has its own profile stored in `ROGUDB`
* Profiles are keyed by `Character-Realm`
* Emote definitions are shared account-wide
* Slot instances, fallback settings, and enabled state are per character
* Legacy configurations are migrated automatically on first login

━━━━━━━━━━━━━━━━━━

**What RoarGuild Is Not**

* Not a DPS tool
* Not a combat automation addon
* Not a macro replacement

It exists purely to add texture, timing, and personality to moment-to-moment play.

━━━━━━━━━━━━━━━━━━

**Guiding Thought**

**Characters are not loadouts.**
**They are stories in motion.**

More info and discussion:
https://discord.gg/7J2QvXCMdE
