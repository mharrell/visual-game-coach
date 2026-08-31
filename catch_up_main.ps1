<#
.SYNOPSIS
  Commit all uncommitted worktree changes and catch local main up with every
  worktree branch, then push main and clean up merged worktrees/branches.

.DESCRIPTION
  This is the "commit everything and catch main up" step for the worktree
  workflow. It:
    1. commits all uncommitted changes in every non-locked worktree branch,
    2. merges each branch into main,
    3. pushes main to origin,
    4. removes the merged worktrees and deletes their branches.

  Run it from anywhere in the repo (it uses `git -C` with absolute paths).
  Locked worktrees (an active Claude session) are skipped. Safe to re-run:
  already-merged branches are skipped.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File catch_up_main.ps1
  powershell -ExecutionPolicy Bypass -File catch_up_main.ps1 -Message "my change"
  powershell -ExecutionPolicy Bypass -File catch_up_main.ps1 -NoPush -KeepWorktrees
#>
param(
    [string]$Message = "",      # optional commit message; auto-generated if empty
    [switch]$NoPush,            # don't push branches/main to origin
    [switch]$KeepWorktrees      # don't remove merged worktrees/branches
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([string[]]$Args)
    & git @Args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Args -join ' ') failed (exit $LASTEXITCODE)"
    }
}

# --- Parse `git worktree list --porcelain` into blocks ----------------------
$blocks = @()
$cur = @{}
foreach ($line in (git worktree list --porcelain)) {
    if ($line -eq "") {
        if ($cur.Count) { $blocks += ,$cur; $cur = @{} }
        continue
    }
    if ($line -like "worktree *")            { $cur.path   = $line.Substring(9) }
    elseif ($line -like "branch refs/heads/*") { $cur.branch = $line.Substring(18) }
    elseif ($line -like "locked*")           { $cur.locked = $true }
}
if ($cur.Count) { $blocks += ,$cur }

# Main checkout = the worktree whose branch is main.
$main = $blocks | Where-Object { $_.branch -eq "main" } | Select-Object -First 1
if (-not $main) { throw "Could not find the main checkout in 'git worktree list'." }

# Targets = non-main, non-locked worktrees with a branch.
$targets = @($blocks | Where-Object {
    $_.branch -and $_.path -ne $main.path -and -not $_.locked
})

if ($targets.Count -eq 0) {
    Write-Host "No worktree branches to catch up. Nothing to do."
    exit 0
}

Write-Host "Catching main up with: $($targets.branch -join ', ')"

# --- 1. Commit all uncommitted changes in each worktree ---------------------
foreach ($t in $targets) {
    $dirty = git -C $t.path status --porcelain
    if ($dirty) {
        $msg = if ($Message) { $Message } else {
            "Auto-commit from $($t.branch) ($(Get-Date -Format yyyy-MM-dd))"
        }
        Invoke-Git -C $t.path add -A
        Invoke-Git -C $t.path commit -m $msg
        Write-Host "  committed $($t.branch): $msg"
    } else {
        Write-Host "  $($t.branch): nothing to commit"
    }
    if (-not $NoPush) {
        Invoke-Git -C $t.path push origin $t.branch
    }
}

# --- 2. Merge each branch into main -----------------------------------------
foreach ($t in $targets) {
    git -C $main.path merge-base --is-ancestor $t.branch main
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  $($t.branch): already in main, skipping"
        continue
    }
    Invoke-Git -C $main.path merge $t.branch --no-edit
    Write-Host "  merged $($t.branch) into main"
}

# --- 3. Push main ------------------------------------------------------------
if (-not $NoPush) {
    Invoke-Git -C $main.path push origin main
    Write-Host "  pushed main to origin"
}

# --- 4. Clean up merged worktrees/branches -----------------------------------
if (-not $KeepWorktrees) {
    foreach ($t in $targets) {
        git -C $main.path merge-base --is-ancestor $t.branch main
        if ($LASTEXITCODE -ne 0) { continue }   # only remove fully-merged
        Invoke-Git -C $main.path worktree remove $t.path --force
        Invoke-Git -C $main.path branch -d $t.branch
        Write-Host "  removed worktree + branch $($t.branch)"
    }
    Invoke-Git -C $main.path worktree prune
}

Write-Host "Done. Main is caught up."
