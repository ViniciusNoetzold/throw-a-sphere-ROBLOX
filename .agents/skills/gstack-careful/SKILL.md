---
name: gstack-careful
description: "Safety mode. Warns before destructive commands (rm -rf, DROP TABLE, git push -f, force delete). Does NOT restrict file editing scope — use /guard for that."
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
  --skill "careful" --duration "$_TEL_DUR" --outcome "OUTCOME" \
  --used-browse "false" --session-id "$_SESSION_ID" 2>/dev/null &
```


# /careful: Destructive Command Safety

Activates heightened awareness for destructive operations. When active, flag and confirm before executing any potentially destructive command.

## What triggers a warning

| Pattern | Risk | Action |
|---------|------|--------|
| `rm -rf` (except node_modules, .next, dist, build, __pycache__) | File deletion | Confirm before executing |
| `git push -f` / `git push --force` | History rewrite | Confirm + warn about remote impact |
| `git reset --hard` | Uncommitted work loss | Confirm + suggest stash first |
| `git clean -f` | Untracked file deletion | Confirm + list what will be deleted |
| `git branch -D` | Branch deletion | Confirm + check if merged |
| `DROP TABLE` / `DROP DATABASE` | Data destruction | Confirm + verify environment |
| `TRUNCATE` | Data deletion | Confirm |
| `docker system prune` | Container cleanup | Confirm |
| Kill/stop commands on game servers | Service disruption | Confirm + check player count |

## Safe exceptions (no warning needed)

```
rm -rf node_modules/
rm -rf .next/
rm -rf dist/
rm -rf build/
rm -rf __pycache__/
rm -rf .cache/
rm -rf tmp/
git push (without -f)
```

## Activation

This skill is activated by invoking `/careful`. It stays active for the remainder of the session.

When active, before any Bash command that matches a warning pattern:

> ⚠️ **CAREFUL MODE**: This command will [describe impact].
> Affected: [list files/data/branches]
> Reversible: [yes/no/partially]
>
> Proceed? (confirm to execute)

## Deactivation

Say "turn off careful mode" or start a new session.

## Review Log

```bash
[ -n "$_GG_BIN" ] && "$_GG_BIN/gstack-review-log" '{"skill":"careful","timestamp":"TIMESTAMP","status":"ACTIVATED","commit":"COMMIT"}' 2>/dev/null || true
```
