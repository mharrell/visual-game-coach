# visual-game-coach — umbrella

This repo is the home of the **shared pattern** for AI-assisted game coaches
(one subdirectory per game). It is no longer the home of any coach.

**Bob's Ledger (Hearthstone Battlegrounds) moved out on 2026-10-02:**
<https://github.com/mharrell/bobs-ledger>. Its code, meta DB, tests, release
channel (`telemetry/`) and history live there now. This repo keeps the
pattern doc (`.claude/skills/coach-pattern/`) and the sync/worktree tooling
for the next game.

## Why it split

A player arriving here could not tell what the coach was. The umbrella README
pitched "AI-assisted game coaches", and the shipped docs carried 34
references to language models — while the coach itself calls no model during
play. A repo whose framing describes something the product is not confuses
exactly the people it is for.

Moving also let the coach's history be rewritten: it contained the
maintainer's BattleTag, an opponent's handle and local profile paths from
research notes. The extraction rewrote every commit, so the coach's history
scans clean. **This repo's history still contains that material** — treat it
as an archive, and use the coach repo for anything coach-shaped.

## Worktree discipline (still applies here)

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
- Branch from FRESH main. Starting from a stale base is how the same bug got
  fixed twice on two branches.

## The shared pattern (one line each)

1. **Pick a coaching-friendly game** — turn-based / decision-timed, where
   good play is *strategic and verbal*, not reflex. That's the LLM's strength
   (in the games where an LLM is used at all — Bob's Ledger is rule-based and
   calls no model).
2. **Hybrid architecture** — the coach reasons over (live state + curated
   meta reference + optional aggregate stats).
3. **Mine the game's own logs** — replays/logs contain more than the player
   sees. This is the data asset.
4. **Structured meta reference** — a JSON DB in `meta/`, refreshed on
   patches, fetched per-decision (only the relevant subset).
5. **breakoutBot discipline** — verify what a vision model actually reads;
   observational data is not causal; sham-control any "coaching helps" claim;
   design before implementing.

Details in `.claude/skills/coach-pattern/SKILL.md`. The reference
implementation is Bob's Ledger — read it in its own repo, where the code sits
at the root and the release zip is the tree.
