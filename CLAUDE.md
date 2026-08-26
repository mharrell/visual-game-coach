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
4. **Curated meta screenshots** — user-taken, refreshed on patches, fetched
   per-decision (only the relevant subset), not all at once.
5. **breakoutBot discipline** — verify what a vision model actually reads;
   observational data is not causal; sham-control any "coaching helps" claim;
   design before implementing.

## Working notes

- Hearthstone logs live at `C:\Program Files (x86)\Hearthstone\Logs\...` (see the
  `hearth-powerlog-locate` skill).
- `hearth-coach/parse_bg.py` needs `hslog` deps from PyPI (network was down at
  bootstrap; retry as needed).
