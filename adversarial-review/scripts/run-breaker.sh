#!/usr/bin/env bash
# run-breaker.sh <base> <out-dir> CONTEXT="..." SPEC_TEXT=@file RULES_FILE=path CI_COMMAND="..." [MODEL] [EFFORT]
# Executing reviewer in a throwaway worktree: workspace-write sandbox, NO network (so push/merge
# are impossible), plain codex exec (review mode is diff-scoped and discourages execution).
set -euo pipefail
base=$1; out=$2; shift 2; kv=(); while [ $# -gt 0 ] && [[ $1 == *=* ]]; do kv+=("$1"); shift; done
model=${1:-gpt-6-astra}; effort=${2:-high}
dir=$(cd "$(dirname "$0")/.." && pwd); mkdir -p "$out"
pkg=$("$dir/scripts/review-package" "$base" HEAD "$out/package.diff")
wt="$out/wt"; git worktree add --detach "$wt" HEAD >/dev/null
# never remove blind: a link inside the worktree (node_modules -> the real one) is followed by
# --force and wipes the original (2026-09-03). Unlink links first, then remove.
# Two passes: POSIX symlinks (find -type l; also what MSYS/Git Bash reports), then Windows reparse
# points (junctions are not -type l under MSYS). Directory.Delete on a reparse point removes the link
# only and never recurses into the target. cmd.exe /c from Git Bash does not work (MSYS rewrites /c
# and mangles quotes; the junction survived). The PowerShell pass was verified on a Windows machine
# on 2026-09-13; on Linux powershell.exe is absent and the block is skipped.
cleanup() {
  find "$wt" -type l -exec rm -f {} + 2>/dev/null || true
  if command -v powershell.exe >/dev/null 2>&1; then
    wtw=$(cygpath -w "$wt" 2>/dev/null || echo "$wt")
    powershell.exe -NoProfile -Command \
      "Get-ChildItem -LiteralPath '$wtw' -Recurse -Force -Attributes ReparsePoint | ForEach-Object { [System.IO.Directory]::Delete(\$_.FullName) }" \
      2>/dev/null || true
  fi
  git worktree remove --force "$wt" 2>/dev/null || true
}
trap cleanup EXIT
prompt=$("$dir/scripts/fill-template" "$dir/templates/breaker.md" "TARGET=$pkg" "${kv[@]}")
codex exec --cd "$wt" -s workspace-write -c sandbox_workspace_write.network_access=false \
  -m "$model" -c model_reasoning_effort="$effort" --json -o "$out/breaker.md" "$prompt" \
  > "$out/breaker.events.jsonl"
"$dir/scripts/check-findings" "$out/breaker.md" "$pkg" | tee "$out/breaker.check"
