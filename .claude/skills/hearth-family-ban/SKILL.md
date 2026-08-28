---
name: hearth-family-ban
description: Determine the 5 allowed / 5 banned tribes for a Battlegrounds game from a Power.log, and filter comps by the family ban. Use when the coach needs to know which tribes are playable in a given game, or which comps are available.
---

# Family Ban — 5 allowed / 5 banned tribes per game

Each Battlegrounds game allows **exactly 5 tribes** and bans the other 5
(verified across the user's recent replays — always 5/5, not "~half"). A comp is
playable only if **every core card has at least one tribe in the allowed set**.

## Detect the 5 allowed tribes from a Power.log

The allowed tribes are the **pure single-tribe minions** in the tavern minion
pool. In the log, pool minions are `BACON_POOL_MINION` entities (SHOW_ENTITY /
FULL_ENTITY blocks tagged `BACON_POOL_MINION`). For each pool minion, look up its
card's tribe set (from the hearthstonejson card DB — `races` field).

- A **pure** minion (exactly one tribe) is in the pool only if that tribe is
  active → the set of pure tribes present = the 5 allowed.
- A **compound** minion (e.g. MECHANICAL/MURLOC) appears if *any* of its tribes
  is active, so it **cannot** reveal bans — ignore compound minions for detection.

The 5 tribes with no pure minion in the pool are banned.

## Filter comps by the ban

A comp is playable if **every core card**:
- is neutral (no tribe) or all-tribe (`ALL`) → always available, or
- has at least one tribe in the allowed set → available, or
- has an unknown tribe → fail open (never wrongly exclude).

Compound core cards (e.g. `DEMON/QUILBOAR`) are playable if *either* tribe is
allowed. Filter by each core card's full tribe set, **not** the comp's `tribe`
field — a Demon deck with a Pirate core card is unavailable when Pirates are
banned.

## Implementation

`hearth-coach/bans.py`:
- `bans_from_log(powerlog_path)` → per-game `{seed, allowed, banned}` (canonical
  tribe names). Uses the card DB cached at `.card_races.json`.
- `filter_comps_by_available_tribes(comps, card_races, allowed_tribes)` → the
  playable comps.

CLI: `python bans.py <Power.log>` prints per-game allowed/banned.

## Related

- `hearth-coach/meta/comps.json` (core card ids), `meta/cards.json` (per-card
  tribe, incomplete), the full card DB (`.cards_full.json`).
- Memory `hearth-family-ban`.
