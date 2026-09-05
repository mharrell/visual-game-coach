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
- `hearth-coach/` tools: `board_state.py` (board parse; spending-aware gold),
  `bans.py` (per-game 5/5 family ban + comp filter), `scrape_comps.py`
  (hsreplay comps), `coach_llm.py` (GLM 5.3 flash client, provider-agnostic),
  `value.py`
  (minion value + sell ranking + shop ranking (minions and tavern spells) +
  top move — real upgrade button prices, level-vs-board rule, comp-pivot
  tracking), `simulate_growth.py` (deterministic growth simulator, engine
  model in `meta/engines.json`), `coach.py` (situation analysis loop),
  `live_coach.py` (incremental live coach), `live.py` (live Power.log monitor
  + overlay server), `coach_ui.py` (overlay: three-column Decide/Build/Market
  layout, prices, art), `choices.py` (hero/trinket/discover pick ranking),
  `validate_growth.py` (simulator validation), `replay_review.py` (per-phase
  coach-vs-player diff), `replay_stats.py` (replay-analysis pipeline → corpus
  stats), `hearth_art_extract.py` (UnityPy card-art extraction from the local
  client, 100% coverage), `sanitize_log.py` (BattleTag redaction),
  `decision_log.py` + `package_corpus.py` + `upload_corpus.py` (beta corpus →
  private repo `mharrell/hearth-telemetry`). Meta DB in `hearth-coach/meta/`;
  suite: `python -m unittest discover -s tests`.
- BG tavern upgrade prices are dynamic: start at (target+3) gold and drop 1
  at the start of each round you wait — the coach reads the live button COST
  from the log; a minion's buy price is its tavern TIER (mana `cost` is
  never the buy price). A BG minion costs its tier in gold.
- Privacy: Power.log's only personal data is BattleTags (no IPs, emails,
  paths, or account IDs) — `sanitize_log.py` redacts them before anything
  leaves the machine. HSReplay does not share replay data; the beta gathers
  our own corpus (see `decision_log.py`).
- hsreplay's minions/heroes/dark-gifts APIs are Cloudflare-protected (403) —
  those meta assets come from manual paste; comps/trinkets pages are
  scrapable. The wiki (hearthstone.wiki.gg) is NOW Cloudflare-blocked too
  (2026-09-03) — card art comes from the local client instead.
