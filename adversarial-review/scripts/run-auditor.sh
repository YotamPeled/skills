#!/usr/bin/env bash
# run-auditor.sh <base> <out-dir> CONTEXT="..." SPEC_TEXT=@file RULES_FILE=path [MODEL] [EFFORT]
# 2026-09-13: codex 0.153 rejects `exec review --base` together with a custom prompt, so the auditor is a plain
# read-only `codex exec` carrying our template (the built-in review rubric no longer applies underneath).
set -euo pipefail
base=$1; out=$2; shift 2; kv=(); while [ $# -gt 0 ] && [[ $1 == *=* ]]; do kv+=("$1"); shift; done
model=${1:-gpt-6-astra}; effort=${2:-high}
dir=$(cd "$(dirname "$0")/.." && pwd); mkdir -p "$out"
pkg=$("$dir/scripts/review-package" "$base" HEAD "$out/package.diff")
prompt=$("$dir/scripts/fill-template" "$dir/templates/auditor.md" "TARGET=$pkg" "${kv[@]}")
codex exec -s read-only -m "$model" -c model_reasoning_effort="$effort" \
  --json -o "$out/auditor.md" "$prompt" > "$out/auditor.events.jsonl"
"$dir/scripts/check-findings" "$out/auditor.md" "$pkg" | tee "$out/auditor.check"
