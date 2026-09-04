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
**value function + growth simulator** to advise each buy phase: what to buy,
what to sell, whether to level (priced at the real upgrade button), which hero
or trinket to pick. A local overlay shows the advice live in a three-column
layout (Decide / Build / Market) with card art for every card.

### Directory layout

```
hearth-coach/
  *.py            — the tools (see below)
  DESIGN.md       — architecture & design decisions
  ROADMAP.md      — phases & next steps
  analysis/       — design docs (log structure, value function, coaching UI)
  meta/           — the structured meta reference
    comps.json    — comps (core/addon cards, how-to-play)
    cards.json    — curated cards
    minions.json  — BG minions with full card text + tavern tier (the price)
    trinkets.json, dark_gifts.json, heroes.json, tavern_spells.json
    engines.json  — machine-readable growth engines
    guides/       — per-comp engine guides (mined from commentary)
    transcripts/  — raw YouTube auto-transcripts (source for the guides)
    corpus_stats.json — aggregate outcome data from your replays
  img_cache/      — card art (HearthstoneJSON renders + client-extracted)
  tests/          — golden-test suite (python -m unittest discover -s tests)
  python-hslog/   — vendored official HearthSim parser (gitignored)
```

### The tools

| Tool | What it does |
|------|--------------|
| `board_state.py` | Power.log → friendly board + hand + hero state (spending-aware gold) |
| `bans.py` | per-game 5 allowed / 5 banned tribes + comp filter |
| `value.py` | minion value function: sell ranking, shop ranking, top move (real upgrade prices, level-vs-board rule, comp-pivot tracking) |
| `simulate_growth.py` | deterministic growth simulator (engine model in `meta/engines.json`) |
| `coach.py` | batch situation analysis of a game |
| `live_coach.py` | incremental live coach (fast per-buy-phase analysis) |
| `live.py` | live monitor + starts the overlay server |
| `coach_ui.py` | overlay (local HTTP server + HTML page; three columns, prices, art) |
| `choices.py` | hero / trinket / discover pick ranking (season-pass-locked fallback) |
| `replay_review.py` | per-phase coach-recommendation vs player-actions diff |
| `replay_stats.py` | deterministic replay-analysis pipeline (corpus stats) |
| `validate_growth.py` | simulator validation against real games |
| `extend_pool.py`, `parse_*.py`, `scrape_comps.py`, `fetch_transcripts.py` | meta build/refresh |
| `patch_notes.py`, `check_patch_notes.py` | apply official patch notes to the meta DB (dry-run default) |
| `hearth_art_extract.py`, `fetch_art.py` | card art: UnityPy extraction from the local client (100% coverage, GUID-addressed) + HearthstoneJSON pre-fetch |
| `sanitize_log.py` | redact BattleTags from a Power.log before sharing |
| `decision_log.py` | records every advisory (with log basename + byte offset join keys) |
| `package_corpus.py` | one gzipped bundle per session: sanitized log + decisions + manifest |
| `upload_corpus.py` | uploads bundles to the private telemetry repo |

### Usage

**Live coaching** (while Hearthstone is running):
```
cd hearth-coach
python live.py            # starts the overlay; prints http://127.0.0.1:8747/
```
Open the printed URL in Chrome, dock it beside the game. The overlay updates
each buy phase (and mid-turn on every buy/roll/sell) with a top-move headline,
the plan's actual buy (with its tavern price), target comp with art, board,
sell ranking, tavern shop, comps, and banned tribes.

**Analyze one game** (batch):
```
python coach.py <Power.log> [game_index]
```

**Review a game** (coach advice vs what you actually did):
```
python replay_review.py <Power.log> [game_index]   # or --latest
```

**Refresh card art** (after a patch):
```
python hearth_art_extract.py     # pulls 100% of the art from the local client
```

**The beta corpus loop** (advice-vs-outcome data):
```
python upload_corpus.py --latest   # sanitize + package + upload in one command
```
Records every advisory alongside the Power.log (`decision_log.py`), redacts
BattleTags (`sanitize_log.py` — the log's only personal data; a pattern scan
found no IPs, emails, paths, or account IDs anywhere), packages the session
into a single ~5MB bundle (`package_corpus.py`), and uploads it to the private
telemetry repo (`mharrell/hearth-telemetry`; override with
`HEARTH_TELEMETRY_REPO`, auth via the `gh` CLI or `GH_TELEMETRY_TOKEN`).

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
- Tavern upgrade prices change every turn (start at target+3 gold, drop 1 per
  turn you wait) — the coach reads the live button price from the log rather
  than modeling it.
- Privacy: Power.log contains no machine identifiers; its only personal data is
  BattleTags, which `sanitize_log.py` redacts to P1/P2/... before anything
  leaves the machine.