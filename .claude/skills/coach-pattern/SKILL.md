---
name: coach-pattern
description: The reusable methodology for building an AI game coach (the "visual game coach" pattern). Use when bootstrapping a new game coach, designing a coach's architecture, or applying the breakoutBot discipline (verify-what-the-model-reads, observational-not-causal, sham-control eval) to a game.
---

# The Game Coach Pattern

A repeatable recipe for turning a game into an AI-assisted coach. The reference
implementation is `hearth-coach/` (Hearthstone Battlegrounds); apply the same
shape to any new game.

## 1. Pick a coaching-friendly game

The pattern works when coaching is **linguistic and strategic**, not reflex:

| Good target | Bad target |
|-------------|------------|
| Turn-based, decision-timed | Real-time reflex |
| One readable state per decision | Continuous frame stream |
| Good play = strategic reasoning | Good play = mechanical tracking |
| Output = "buy this, level next, pivot to X" | Output = "move right now" |

An LLM's strength is verbal reasoning over a discrete state — pick games where
that's the actual skill being coached.

## 2. Hybrid architecture

```
              COACH AGENT (LLM)
   reasons over (state + meta + stats)
        /            |            \
  live state    meta reference   optional stats
  (parse logs   (curated         (aggregate API,
   or OCR)       screenshots)      if accessible)
```

Two context layers, reasoned over simultaneously:
1. **Live state** — the specific situation (board, resources, opponents).
2. **Meta knowledge** — general knowledge (tier lists, rankings), as curated
   screenshots the user takes and refreshes on patches.

## 3. Mine the game's own logs (the data asset)

Most games write richer logs/replays than the player sees. In Hearthstone, one
`Power.log` game contains the **full move stream of all 8 players** — so every
game you play yields ~8 decision trajectories, not just your own. The tracker
apps persist only *your* final board; the raw log is richer.

- Find where the game writes logs (see `hearth-powerlog-locate` for the pattern).
- Prefer the game's official/community parser if one exists (e.g. `python-hslog`).
- Validate the parse on real data before building on it.

## 4. Curated meta reference (locked decision)

- **Source:** screenshots the user takes; refreshed manually on patches.
- **Fetch:** only the relevant subset per decision (hero-rank sheet only on the
  hero-select turn), never the whole library.
- **Legibility is the real risk:** meta sheets are dense with small text. Scale/
  crop dense text, and pair each image with a short text caption as a fallback.

## 5. breakoutBot discipline (non-negotiable)

1. **Verify what a vision model actually reads** before trusting image-derived
   advice (dead-model/confound discipline).
2. **Observational data is not causal.** "Players who took X placed better" is a
   correlation. Bucket + build outcome tables before claiming anything.
3. **Sham-control any "coaching helps" claim.** A sham coach gives
   plausible-but-random advice; if players feel it "helps," the signal is not
   evidence of real help.
4. **Design decisions before implementation.**
5. **Don't attribute an outcome to one variable** without listing the others.

## 6. Bootstrap checklist for a new game

1. Create `<game>-coach/` with `DESIGN.md` + `ROADMAP.md`.
2. Locate the game's logs/replays and confirm they contain opponent/full-move data.
3. Find or write a parser; validate it on one real session.
4. Curate the meta screenshots and verify the model reads them.
5. Build the coach agent (state + meta + optional stats → explainable advice).
6. Design the sham-control evaluation *before* claiming the coach helps.

## Reference

- Hearthstone implementation: `hearth-coach/DESIGN.md`, `hearth-coach/ROADMAP.md`,
  `hearth-coach/analysis/OPPONENT_DATA.md`.
- Game-specific skills: `hearth-board-extract`, `hearth-powerlog-games`,
  `hearth-powerlog-locate`.
