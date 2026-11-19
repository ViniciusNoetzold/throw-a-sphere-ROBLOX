---
name: gstack-unfreeze
description: "Deactivate /guard scope restriction. Returns to normal editing mode."
user_invocable: true
preamble-tier: 1
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
<!-- Regenerate: bun scripts/gen-skill-docs.ts -->

## Project-local setup

Use `docs/reviews/gstack/` for shared review artifacts in this repository. Create it only when producing a review. The original Bash/Bun preamble and session analytics are not required for reading these instructions in Codex. Supporting files are in `vendor/skill-sources/fagemx--gstack-game/`. Map tool names to the tools actually available. Do not execute telemetry or install hooks.

## User Sovereignty

AI models recommend. You decide. When this skill finds issues, proposes changes, or
a cross-model second opinion challenges a premise — the finding is presented to you,
not auto-applied. Cross-model agreement is a strong signal, not a mandate. Your
direction is the default unless you explicitly change it.

## Public Output Redaction Lite

Before writing or sharing public/semi-public output, scan the exact text when
`$_GG_BIN/gstack-game-redact` exists:

```bash
printf '%s' "$OUTPUT_TEXT" | "$_GG_BIN/gstack-game-redact" --json
```

Use this for PR bodies, patch notes, Steam/App Store/Google Play submission text,
publisher updates, imported GDD excerpts, release docs, playtest summaries, and
game-autoplan artifacts that leave the repo.

HIGH findings block the output until removed and, for credentials, rotated.
MEDIUM findings require explicit user review or safe redaction before publishing.
Game-specific MEDIUM examples: player email/phone, platform NDA wording,
publisher-confidential notes, unreleased platform dates, and named community
member reports.

## Completion Status Protocol

DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT.
Escalation after 3 failed attempts.


## Telemetry (run last)

```bash
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
[ -n "$_GG_BIN" ] && "$_GG_BIN/gstack-telemetry-log" \
  --skill "unfreeze" --duration "$_TEL_DUR" --outcome "OUTCOME" \
  --used-browse "false" --session-id "$_SESSION_ID" 2>/dev/null &
```


# /unfreeze: Deactivate Guard Mode

Removes the file edit scope restriction set by `/guard`.

## What it does

1. Clears the active scope restriction
2. Confirms deactivation
3. `/careful` protections remain active if they were enabled separately

## Usage

Just invoke `/unfreeze`. No arguments needed.

> Guard mode deactivated. All files are now editable.
> Note: If /careful was active, destructive command warnings are still on.

## Review Log

```bash
[ -n "$_GG_BIN" ] && "$_GG_BIN/gstack-review-log" '{"skill":"unfreeze","timestamp":"TIMESTAMP","status":"DEACTIVATED","commit":"COMMIT"}' 2>/dev/null || true
```
