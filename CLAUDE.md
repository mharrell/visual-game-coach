# Visual Game Coach

Umbrella project for AI-assisted game coaches. One subdirectory per game, all
following a shared pattern (see `.claude/skills/coach-pattern/`).

## Games

- `hearth-coach/` — Hearthstone Battlegrounds coach (reference implementation).
  Docs: `hearth-coach/DESIGN.md`, `hearth-coach/ROADMAP.md`,
  `hearth-coach/analysis/*.md`.

## The shared pattern (one line each)

1. **Pick a coaching-friendly game** — turn-based / decision-timed, where good
   play is *strategic and verbal*, not reflex. That's the LLM's strength.
2. **Hybrid architecture** — the coach reasons over (live board state + curated
   meta reference + optional aggregate stats).
3. **Mine the game's own logs** — replays/logs contain more than the player sees
   (opponent data, full move streams). This is the data asset.
4. **Structured meta reference** — a JSON DB (comps, cards, trinkets, dark gifts,
   heroes, minions, tavern spells) in `hearth-coach/meta/`, refreshed on patches,
   fetched per-decision (only the relevant subset), not all at once.
5. **breakoutBot discipline** — verify what a vision model actually reads;
   observational data is not causal; sham-control any "coaching helps" claim;
   design before implementing.

## Working notes

- Hearthstone logs live at `C:\Program Files (x86)\Hearthstone\Logs\...` (see the
  `hearth-powerlog-locate` skill).
- `hearth-coach/` tools: `board_state.py` (board parse), `bans.py` (per-game
  5/5 family ban + comp filter), `scrape_comps.py` (hsreplay comps),
  `coach_llm.py` (DeepSeek v4 flash client), `value.py` (minion value + sell
  ranking + shop ranking (minions and tavern spells) + top move),
  `simulate_growth.py` (deterministic growth
  simulator, 13 engines in `meta/engines.json`), `coach.py` (situation analysis
  loop), `live_coach.py` (incremental live coach), `live.py` (live Power.log
  monitor + overlay server), `coach_ui.py` (V1 overlay), `validate_growth.py`
  (simulator validation), `replay_stats.py` (replay-analysis pipeline → corpus
  stats). Meta DB in `hearth-coach/meta/`.
- hsreplay's minions/heroes/dark-gifts APIs are Cloudflare-protected (403) —
  those meta assets come from manual paste; comps/trinkets pages and the wiki
  (hearthstone.wiki.gg) are scrapable.
