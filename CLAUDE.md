# Visual Game Coach

Umbrella project for AI-assisted game coaches. One subdirectory per game, all
following a shared pattern (see `.claude/skills/coach-pattern/`).

## Worktree discipline

- Code work happens in git worktrees under `.claude/worktrees/`. **Main is the
  only truth; origin is backup. If it's not in main, it's not done.**
- Every session that touched code ends with `powershell -File
  catch_up_main.ps1` (commit, merge into main, push, clean up) — or ends by
  explicitly reporting "branch X, N commits, NOT merged". A Stop hook
  (`wt_status.ps1 -RemindOnly`) nags once when unmerged work exists at session
  end. Locked worktrees are skipped — whoever closes that session re-runs the
  script once; it is safe to re-run at any time.
- `powershell -File wt_status.ps1` answers "is everything merged?" in one
  command: per-branch dirty/ahead counts (patch-equivalence-aware via
  `git cherry`), plus origin-only leftovers. No git archaeology.
- Branch from FRESH main (EnterWorktree's default bases off origin/main).
  Starting from a stale base is how the same bug got fixed twice on two
  branches (2026-09-10: comp-progress crash, two parallel fixes).
- After a merge, the merged remote branch is deleted too (the script does it).
  Memory/notes cite only shas that are actually reachable from main — until a
  branch lands, name the branch, not the sha.

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
  tracking; combat-phase stat gains are non-persistent per player rule
  2026-09-11 — combat-only buff-givers are W_COMBAT_SCALE power, not growth
  engines), `simulate_growth.py` (deterministic growth simulator, engine
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
  from the log. **Minions cost a FLAT 3 gold, all tiers** (player-confirmed
  2026-09-06; log ground truth: Buzzing Vermin/Decoy Conjurer charged
  RESOURCES_USED=3 while their entity `tag=479` said 1 — minion COST tags
  are stale legacy tier costs and must not be trusted, nor is the DB
  `tier` a price). Tavern spells keep their own per-spell prices (log COST
  tag via `shop_cost_map`, else the spell DB) — `value._buy_prices` is the
  one price layer both the affordability walk and the overlay use.
- Privacy: Power.log's only personal data is BattleTags (no IPs, emails,
  paths, or account IDs) — `sanitize_log.py` redacts them before anything
  leaves the machine. HSReplay does not share replay data; the beta gathers
  our own corpus (see `decision_log.py`).
- hsreplay's minions/heroes/dark-gifts APIs are Cloudflare-protected (403) —
  those meta assets come from manual paste; comps/trinkets pages are
  scrapable. The wiki (hearthstone.wiki.gg) is NOW Cloudflare-blocked too
  (2026-09-03) — card art comes from the local client instead.
