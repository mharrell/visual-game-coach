#!/usr/bin/env bash
# Stop hook (2026-09-10 worktree discipline): nag ONCE when worktree branches
# hold unmerged work at session end. Clean runs are silent.
#
# Behavior on unmerged work: blocks the stop once (decision:block) telling the
# model to either run catch_up_main.ps1, report the branch as NOT merged, or
# touch the per-session ack latch (.claude/wt-status/<session>.ack) if staying
# unmerged is the deliberate outcome. The latch keeps this from nag-looping.
# Fails open: missing env / no worktree branches / powershell trouble never
# block a session.
set -u
[ -n "${CLAUDE_PROJECT_DIR:-}" ] || exit 0
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

# Fast path (no PowerShell startup on the common stop): nothing to check when
# no local worktree branches exist and no origin-only worktree-* branches linger.
if [ "$(git worktree list --porcelain 2>/dev/null | grep -c '^branch refs/heads/')" -le 1 ] \
   && [ "$(git for-each-ref refs/remotes/origin --format='%(refname:short)' 2>/dev/null | grep -c '^origin/worktree-')" -eq 0 ]; then
    exit 0
fi

input=$(cat)
session_id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
session_id=${session_id:-unknown}
ack=".claude/wt-status/$session_id.ack"
[ -f "$ack" ] && exit 0   # already acknowledged this session

# Relative script path: powershell -File splits absolute paths at spaces when
# the args travel bash -> powershell (this project path has a space).
out=$(powershell -NoProfile -NonInteractive -File wt_status.ps1 -RemindOnly 2>&1)
status=$?
if [ "$status" -eq 0 ]; then
    rm -f "$ack" 2>/dev/null   # merged since - clear a stale latch
    exit 0
fi

# Unmerged work exists: block the stop once, with the way out stated.
summary=$(printf '%s' "$out" | tr -d '\r' \
    | grep -v -e '^Windows PowerShell' -e 'Copyright' -e 'reserved\.' \
              -e '^[[:space:]]*$' \
    | head -4 | paste -sd ';' -)
printf '{"decision":"block","reason":"Unmerged worktree work at session end - %s. Run `powershell -File catch_up_main.ps1` from the repo root to commit+merge+push+clean up, or state explicitly in your final message that the branch is NOT merged. If staying unmerged is the deliberate outcome, acknowledge it and stop again: mkdir -p .claude/wt-status && touch .claude/wt-status/%s.ack"}\n' \
    "$summary" "$session_id"
exit 0
