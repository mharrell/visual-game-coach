# visual-game-coach

Umbrella repo for AI-assisted game coaches. **The Hearthstone Battlegrounds
coach that lived here now has its own home:**

## → [mharrell/bobs-ledger](https://github.com/mharrell/bobs-ledger)

Bob's Ledger moved out on 2026-10-02. This repo had grown around it — a
multi-game pattern doc, worktree plumbing, and a pitch about "AI-assisted
coaches" — and a player arriving here could not tell what the coach actually
was. It is a **rule-based** coach: it reads Hearthstone's own logs, reasons
over your actual board with a value function and a growth simulator, and
calls no model at all during play.

The move also fixed a real problem: the coach's history in this repo
contains the maintainer's BattleTag, an opponent's handle and local profile
paths, picked up from research notes. Extracting the history into a new
repository rewrote every commit, so that material is gone from the coach's
history — it still sits in this repo's. Treat what is here as an archive,
not a source of truth.

- **Coach repo:** <https://github.com/mharrell/bobs-ledger>
- **What remains here:** the shared coach pattern
  (`.claude/skills/coach-pattern/`) and the sync/worktree tooling, for the
  next game.
