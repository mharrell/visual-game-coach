<#
.SYNOPSIS
  One-command answer to "is everything merged?" for the worktree workflow.

.DESCRIPTION
  The exact checks the 2026-09-10 session had to do by git-cherry archaeology,
  as one table:
    - every worktree branch: worktree present? dirty files? commits ahead of
      main (patch-equivalence-aware via `git cherry` - a rebase/duplicate that
      main already contains reads as merged)?
    - origin-only worktree-* branches (no local worktree): fully merged
      (prune candidate) or still carrying unmerged commits?
  Exit 0 either way; the verdict line is the yes/no answer.

  -RemindOnly prints NOTHING when everything is merged, and a one-line warning
  per unmerged branch otherwise (exit 1) - the Stop hook's nag mode.

  NOTE: keep this file pure ASCII - Windows PowerShell 5.1 reads non-BOM files
  as ANSI, and UTF-8 punctuation inside string literals decodes to stray
  quote characters there (parse errors).
.EXAMPLE
  powershell -File wt_status.ps1
  powershell -File wt_status.ps1 -RemindOnly
#>
param(
    [switch]$RemindOnly   # print only unmerged-work warnings (Stop hook)
)

$ErrorActionPreference = "Stop"

# Read-only git: returns an array of output lines (empty = command succeeded
# with no output), or $null when the command itself failed.
function Get-Git {
    param([string[]]$GitArgs)
    $out = & git @GitArgs 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return ,@($out | Where-Object { $null -ne $_ })
}

# --- Parse `git worktree list --porcelain` (same shape as catch_up_main) ----
$blocks = @()
$cur = @{}
foreach ($line in (git worktree list --porcelain)) {
    if ($line -eq "") {
        if ($cur.Count) { $blocks += ,$cur; $cur = @{} }
        continue
    }
    if ($line -like "worktree *")              { $cur.path   = $line.Substring(9) }
    elseif ($line -like "branch refs/heads/*") { $cur.branch = $line.Substring(18) }
}
if ($cur.Count) { $blocks += ,$cur }

$main = $blocks | Where-Object { $_.branch -eq "main" } | Select-Object -First 1
if (-not $main) { throw "Could not find the main checkout in 'git worktree list'." }

# Unmerged-commits count via git cherry ('+' = commit main lacks, even if an
# equivalent patch landed under a different sha; '-' = already in main).
# -1 = unknown (branch gone / git failed).
function Get-Unmerged {
    param([string]$Branch)
    $cherry = Get-Git @("cherry", "main", $Branch)
    if ($null -eq $cherry) { return -1 }
    return @($cherry | Where-Object { $_.StartsWith("+") }).Count
}

$problems = @()

# --- Local worktree branches -------------------------------------------------
$targets = @($blocks | Where-Object {
    $_.branch -and $_.branch -ne "main"
})
if (-not $RemindOnly) {
    if ($targets.Count -eq 0) { Write-Host "no local worktree branches" }
    else {
        Write-Host ("{0,-44} {1,6} {2,6}  {3}" -f
            "BRANCH", "DIRTY", "AHEAD", "STATE")
        foreach ($t in $targets) {
            $statusOut = Get-Git @("-C", $t.path, "status", "--porcelain")
            $dirty = if ($null -eq $statusOut) { "?" }
                     else { @($statusOut).Count }
            $ahead = Get-Unmerged $t.branch
            $state = if ($ahead -lt 0) { "unknown" }
                     elseif ($ahead -gt 0) { "NOT MERGED" }
                     else { "in main" }
            Write-Host ("{0,-44} {1,6} {2,6}  {3}" -f
                $t.branch, $dirty, $(if ($ahead -lt 0) { "?" } else { $ahead }),
                $state)
        }
    }
}
foreach ($t in $targets) {
    $ahead = Get-Unmerged $t.branch
    if ($ahead -gt 0) {
        $problems += "$($t.branch): $ahead commit(s) not in main"
    }
}

# --- Origin-only worktree branches (worktree gone, branch still on origin) ---
$localBranches = Get-Git @("for-each-ref", "refs/heads/",
                           "--format=%(refname:short)")
if ($null -eq $localBranches) { $localBranches = @() }
$remoteBranches = Get-Git @("for-each-ref", "refs/remotes/origin/",
                            "--format=%(refname:short)")
$originOnly = @()
foreach ($r in ($remoteBranches | Where-Object { $_ })) {
    $b = $r -replace "^origin/", ""
    if ($b -notlike "worktree-*" -or $localBranches -contains $b) { continue }
    $ahead = Get-Unmerged "origin/$b"
    if ($ahead -lt 0) { continue }
    $originOnly += [pscustomobject]@{ Branch = $b; Ahead = $ahead }
    if ($ahead -gt 0) {
        $problems += "origin/$b (no local worktree): $ahead commit(s) not in main"
    }
}
if (-not $RemindOnly -and $originOnly.Count) {
    Write-Host ""
    Write-Host "ORIGIN-ONLY worktree branches (worktree gone):"
    foreach ($o in $originOnly) {
        $state = if ($o.Ahead -gt 0) { "NOT MERGED - merge or delete deliberately" }
                 else { "fully merged - prune candidate" }
        Write-Host ("  {0,-44} {1}" -f $o.Branch, $state)
    }
}

# --- Verdict -----------------------------------------------------------------
if ($RemindOnly) {
    if ($problems.Count) {
        $problems | ForEach-Object { Write-Warning $_ }
        Write-Host "End-of-session rule: run 'powershell -File catch_up_main.ps1' to merge+push, or explicitly report the branch as NOT merged."
        exit 1
    }
    exit 0
}

Write-Host ""
if ($problems.Count) {
    Write-Host "UNMERGED WORK EXISTS - not everything is in main:"
    $problems | ForEach-Object { Write-Host "  $_" }
    Write-Host "Run: powershell -File catch_up_main.ps1"
} else {
    Write-Host "EVERYTHING IS MERGED - main is the whole story."
}
exit 0
