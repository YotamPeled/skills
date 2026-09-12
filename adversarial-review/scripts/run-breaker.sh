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
trap 'git worktree remove --force "$wt" 2>/dev/null || true' EXIT
prompt=$("$dir/scripts/fill-template" "$dir/templates/breaker.md" "TARGET=$pkg" "${kv[@]}")
codex exec --cd "$wt" -s workspace-write -c sandbox_workspace_write.network_access=false \
  -m "$model" -c model_reasoning_effort="$effort" --json -o "$out/breaker.md" "$prompt" \
  > "$out/breaker.events.jsonl"
"$dir/scripts/check-findings" "$out/breaker.md" "$pkg" | tee "$out/breaker.check"
