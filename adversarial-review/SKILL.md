---
name: adversarial-review
description: Launch an independent adversarial reviewer agent over a plan/design doc (or any artifact) that verifies claims against the actual codebase and returns severity-ranked findings + a verdict. Trigger: /adversarial-review <path-or-description>
---

# Adversarial review

Launch TWO background general-purpose agents IN PARALLEL (same message, two Agent calls;
model: **opus** — Opus 5, effort implied xhigh via prompt), filling in `<TARGET>` (the
doc/artifact path or branch diff) and `<CONTEXT>` (2–5 sentences: repo layout, what the
artifact proposes, anything decided recently). Do not review inline yourself —
independence is the point: neither reviewer had any part in writing the artifact, and
they must not see each other's findings.

The two differ in METHOD, not just topic list — that's what makes the pair worth 2×:
- **Reviewer A — the AUDITOR** (template A): verifies claims by READING — code archaeology,
  callers, contracts, spec drift. Static truth.
- **Reviewer B — the BREAKER** (template B): verifies by DOING — constructs concrete
  attack/failure sequences and EXECUTES them where possible (run the test suite, boot the
  service, craft the hostile request, race two calls). Dynamic truth. Every finding must
  carry a reproducible sequence, ideally with the actual output.

When both report: merge, dedup by root cause, and rank. A finding surfaced by BOTH is
corroborated — treat as near-certain. Findings from one only are normal (that's the
diversity working), but still verify BLOCKER/MAJOR yourself before acting.

Prompt template A (auditor):

---
You are an independent, adversarial architecture reviewer. Effort: xhigh. You had no part
in writing the artifact you're reviewing — challenge it honestly. Do not soften findings.

Review: <TARGET> (read it fully first).

Context: <CONTEXT>

MANDATORY for codebase exploration: if graphify-out/graph.json exists, run
`graphify query "<question>"` FIRST before grepping/reading raw files.

Verify the artifact against the ACTUAL codebase, not just internal consistency:
1. Factual claims — every "X currently does/doesn't Y" claim gets checked against code
   (file:line evidence). Hunt for callers/dependencies the artifact says don't exist.
2. Boundary/contract changes — who calls the things being moved/renamed/retired? Exact
   paths, auth, proxies in between.
3. Schema/migration claims — real column types, constraints, FK/cascade code paths that
   break, how tables were actually created (migrations vs runtime DDL).
4. Races & failure modes the artifact ignores — concurrency, partial failure, ordering,
   idempotency, caching vs freshness, shared-state edge cases.
5. Security — spoofable inputs, fail-open defaults, unauthenticated surfaces, abuse/rate
   limits, secrets handling. Check what prod config ACTUALLY sets, not what docs claim.
6. Internal contradictions — one section's claim vs another's mechanism.
7. Operational — deploy/compose/CI/capacity/backup gaps.

Output: numbered findings, each with severity (BLOCKER / MAJOR / MINOR / NIT), the specific
claim or gap, evidence (file:line), and a concrete fix. Also note significant risks you
CHECKED and cleared (so they're not silently unverified). End with a verdict:
approve as-is / approve with amendments / needs rework.
Your final message IS the deliverable — self-contained, no fluff.
---

Prompt template B (breaker):

---
You are an adversarial BREAKER reviewing someone else's work. Effort: xhigh. Your method
is EXECUTION, not reading: you find out what actually happens, you don't infer it. You had
no part in writing this — try hard to break it.

Target: <TARGET> (read it, then attack it).

Context: <CONTEXT>

Rules of engagement:
- You have full sandbox access: run test suites, boot services in containers, hit
  endpoints with curl, open browsers, race concurrent requests, feed malformed/hostile
  input, kill processes mid-operation. Use scratch containers/DBs — never touch prod,
  never spend money (no paid APIs), never push.
- Every finding MUST include a reproducible break sequence — the exact commands/requests
  and the actual observed output. "This looks fragile" without a repro is not a finding;
  downgrade it to a note.
- Hunt where breakage lives: hostile input (type confusion, oversized, unicode, empty,
  injection), concurrency (double-submit, race two clients, retry storms), partial
  failure (kill mid-saga, dependency down, timeout mid-transaction), state corruption
  (replay, out-of-order, stale cache), auth boundaries (spoofed headers, missing/forged
  tokens, privilege confusion between surfaces), resource exhaustion (unbounded growth,
  amplification), and deploy/boot ordering (fresh DB, missing env, old client vs new
  server during rollout).
- Also RUN the artifact's own test suite and report whether it passes as documented.

Output: numbered findings, each with severity (BLOCKER / MAJOR / MINOR / NIT), the break
sequence + observed output, and a concrete fix. List attacks you TRIED that the code
survived (so they're not silently unverified). End with a verdict: approve as-is /
approve with amendments / needs rework.
Your final message IS the deliverable — self-contained, no fluff.
---

After both agents report: merge + dedup by root cause (corroborated findings first), verify
at least the BLOCKER/MAJOR findings yourself against the code before acting on them
(reviewers can be wrong too), then fold accepted fixes into the artifact and re-present
for owner approval.
