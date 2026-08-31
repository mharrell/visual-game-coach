---
name: git-sync-to-main
description: Commit all uncommitted worktree changes and catch local main up with every worktree branch, then push and clean up. Use when work has landed in a git worktree branch and main needs to be brought up to date, or when finishing a worktree-based session.
---

# Sync worktree work to main

Work in this repo is often done in **git worktrees** (under `.claude/worktrees/`),
each on its own branch. That isolates edits, but it means `main` can fall behind
the worktree branches. This skill is the "commit everything and catch main up"
step that brings `main` current and cleans up the merged worktrees.

## The one command

Run from anywhere in the repo (it uses `git -C` with absolute paths):

```powershell
powershell -ExecutionPolicy Bypass -File catch_up_main.ps1
```

What it does, in order:

1. **Commit** all uncommitted changes in every non-locked worktree branch
   (auto message `Auto-commit from <branch> (<date>)`, or pass `-Message`).
2. **Push** each worktree branch to origin (backup before merging).
3. **Merge** each branch into `main`.
4. **Push** `main` to origin.
5. **Clean up** — remove the merged worktrees and delete their branches.

**Locked worktrees are skipped** (an active Claude session sets the `locked`
flag), so a running session is never disturbed.

## Options

| Flag | Effect |
|------|--------|
| `-Message "..."` | Use this commit message instead of the auto-generated one |
| `-NoPush` | Don't push branches or main to origin (local catch-up only) |
| `-KeepWorktrees` | Merge + push but don't remove worktrees/branches |

## Safe to re-run

Already-merged branches are detected (`git merge-base --is-ancestor`) and
skipped, so re-running after a partial failure is safe. If a merge conflicts,
the script stops at that merge — resolve it in the main checkout and re-run.

## Manual fallback (no script)

If you can't run the script, the equivalent steps by hand:

```powershell
# from the main checkout
git worktree list --porcelain          # see the worktree branches
git -C <worktree> add -A && git -C <worktree> commit -m "msg"
git merge <branch> --no-edit           # for each worktree branch
git push origin main
git worktree remove <path> --force     # then: git branch -d <branch>
```

## When to use

- At the end of a worktree-based session, to land the work on `main`.
- Whenever `main` is behind `origin/main` or behind worktree branches.
- After a merge conflict was resolved, to finish the catch-up.

## Note on local vs origin

`catch_up_main.ps1` updates the **local** `main` (the shared checkout) and pushes
it. If you're in an isolated worktree session that can't touch the shared
checkout, run the script yourself (or `! powershell -ExecutionPolicy Bypass -File
catch_up_main.ps1`) from the main checkout.
