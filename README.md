# Visual Game Coach

Umbrella project for AI-assisted game coaches. One subdirectory per game, all
following a shared pattern (see `.claude/skills/coach-pattern/`).

## Games

- **`hearth-coach/`** — Hearthstone Battlegrounds coach (the reference
  implementation). A real-time coaching overlay that reads the live board and
  gives dynamic, explainable advice — competing with HSReplay/Firestone stat
  overlays on *reasoning*, not raw data volume.

## The shared pattern

1. **Pick a coaching-friendly game** — turn-based / decision-timed, where good
   play is *strategic and verbal*, not reflex. That's the LLM's strength.
2. **Hybrid architecture** — the coach reasons over (live board state + curated
   meta reference + optional aggregate stats).
3. **Mine the game's own logs** — replays/logs contain more than the player sees
   (opponent data, full move streams). This is the data asset.
4. **Structured meta reference** — a JSON DB (comps, cards, trinkets, dark gifts,
   heroes, minions, tavern spells) in `hearth-coach/meta/`, refreshed on patches.
5. **breakoutBot discipline** — verify what a vision model actually reads;
   observational data is not causal; sham-control any "coaching helps" claim;
   design before implementing.

---

## `hearth-coach/` — Battlegrounds coach

### What it does

Reads the live Hearthstone `Power.log`, reconstructs your board, and runs a
**value function + growth simulator** to advise each buy phase: what to buy, what
to sell, whether to level. A local overlay shows the advice live.

### Directory layout

```
hearth-coach/
  *.py            — the tools (see below)
  DESIGN.md       — architecture & design decisions
  ROADMAP.md      — phases & next steps
  analysis/       — design docs (log structure, value function, coaching UI)
  meta/           — the structured meta reference
    comps.json    — 20 comps (core/addon cards, how-to-play)
    cards.json    — 89 curated cards
    minions.json  — 245 BG minions with full card text
    trinkets.json, dark_gifts.json, heroes.json, tavern_spells.json
    engines.json  — machine-readable growth engines (13)
    guides/       — per-comp engine guides (mined from commentary)
    transcripts/  — raw YouTube auto-transcripts (source for the guides)
    corpus_stats.json — aggregate outcome data from your replays
  python-hslog/   — vendored official HearthSim parser (gitignored)
```

### The tools

| Tool | What it does |
|------|--------------|
| `board_state.py` | Power.log → friendly board + hand + hero state |
| `bans.py` | per-game 5 allowed / 5 banned tribes + comp filter |
| `value.py` | minion value function: sell ranking, shop ranking, top move |
| `simulate_growth.py` | deterministic growth simulator (13 engines) |
| `coach.py` | batch situation analysis of a game |
| `live_coach.py` | incremental live coach (fast per-buy-phase analysis) |
| `live.py` | live monitor + starts the overlay server |
| `coach_ui.py` | V1 overlay (local HTTP server + HTML page) |
| `validate_growth.py` | simulator validation against real games |
| `replay_stats.py` | deterministic replay-analysis pipeline (corpus stats) |
| `scrape_comps.py`, `parse_*.py`, `fetch_transcripts.py` | meta build/refresh |

### Usage

**Live coaching** (while Hearthstone is running):
```
cd hearth-coach
python live.py            # starts the overlay; prints http://127.0.0.1:8747/
```
Open the printed URL in Chrome, dock it beside the game. The overlay updates
each buy phase with a top-move headline, board, sell ranking, buy ranking, comps,
and banned tribes.

**Analyze one game** (batch):
```
python coach.py <Power.log> [game_index]
```

**Grow the replay corpus** (after each session):
```
python replay_stats.py --save meta/corpus_stats.json
```
This aggregates comp/engine/hero win-rates and card value across all your
Power.logs — the foundation for tuning the simulator and weighting comps by
actual success.

**Validate the simulator** against a real game:
```
python validate_growth.py <Power.log> [game_index]
```

### Notes

- Hearthstone logs live at `C:\Program Files (x86)\Hearthstone\Logs\...`.
- The coach's advice model (an LLM that turns the analysis into coaching text) is
  still an open decision — the current coach is the deterministic reasoning layer.
- The growth simulator is conservative (underestimates real growth ~1.6–2x);
  tuning it against the growing corpus is the next step.
