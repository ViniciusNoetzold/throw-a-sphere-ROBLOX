---
name: gstack-game-docs
description: "Game release documentation update. Generates player-facing patch notes, internal changelog, and updates all project documentation after a release."
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
  --skill "game-docs" --duration "$_TEL_DUR" --outcome "OUTCOME" \
  --used-browse "false" --session-id "$_SESSION_ID" 2>/dev/null &
```


# /game-docs: Release Documentation

Update all documentation after a game release or patch.

## Step 0: Release Context

```bash
# Find recent release info
git tag --sort=-creatordate | head -5
_LATEST_TAG=$(git tag --sort=-creatordate | head -1)
[ -n "$_LATEST_TAG" ] && git log "$_LATEST_TAG"..HEAD --oneline --no-merges | head -20
```

AskUserQuestion: What version is this release? What are the highlights?

## Section 1: Player-Facing Patch Notes

**Format — players read this, not developers:**

```markdown
# Version X.Y.Z — [Catchy Title]

## ✨ New
- [Feature in player language] — [what it means for gameplay]

## ⚡ Improved
- [Improvement] — [why it matters]

## 🐛 Fixed
- [Bug description in player terms] — [what was happening, now fixed]

## ⚖️ Balance Changes
- [What changed] — [designer intent / reasoning]

## 🔧 Known Issues
- [Issue] — [workaround if any]
```

**Rules:**
- No code references, file paths, or technical jargon
- Every change answers "so what?" for the player
- Balance changes include the WHY (players want to understand intent)
- Group by impact, not by code area

**Game-Specific Patch Note Patterns:**

| Change Type | Bad (developer voice) | Good (player voice) |
|-------------|----------------------|---------------------|
| **Nerf** | "Reduced Warrior base damage from 50 to 40" | "Warriors deal less damage in early game. We noticed Warriors were clearing content 30% faster than other classes at low levels — this brings them in line while preserving their late-game power fantasy." |
| **Buff** | "Increased Mage mana regen by 20%" | "Mages recover mana faster. We heard you — running out of mana mid-fight felt punishing. You'll still need to manage resources, but you won't be stuck auto-attacking as often." |
| **Economy** | "Adjusted gold drop rates" | "You'll earn gold slightly faster from quests, but shop prices for top-tier items are higher. The net effect: mid-game feels smoother, but the best gear still requires commitment." |
| **Feel** | "Fixed input latency" | "Attacks now respond faster when you tap. If combat felt 'mushy' before, try it now — we shaved 2 frames off the startup animation." |
| **Remove** | "Removed feature X" | "We've removed [feature]. We know some of you used it, and here's why: [honest reason]. What replaces it: [alternative]." |

**Balance Change Communication Protocol:**
1. State WHAT changed (the numbers)
2. State WHY (the design intent — never leave balance changes unexplained)
3. State the EXPECTED EFFECT ("fights should last 5s longer on average")
4. Acknowledge player impact ("if you main Warrior, this will feel different")
5. Invite feedback ("tell us how this lands after a few sessions")

## Section 2: Internal Changelog

**Format — for the team:**

```markdown
# [version] — [date]

## Changes
- [commit-style description] ([files affected]) @[author]

## Metrics
- LOC changed: ___
- Files changed: ___
- Tests added: ___
- Known debt introduced: ___
```

## Section 3: Documentation Sweep

Check and update:
- [ ] README — Version number, install instructions, screenshots current?
- [ ] GDD — Does it reflect current game state? Mark outdated sections.
- [ ] API docs — If modding/plugin support exists
- [ ] Platform store descriptions — App Store/Steam/Play Store
- [ ] Website/landing page — Screenshots, feature list, trailer

## AUTO/ASK/ESCALATE

- **AUTO:** Generate changelog from git log, update version numbers
- **ASK:** Patch notes tone/framing, which changes to highlight, balance change explanations
- **ESCALATE:** Major undocumented breaking change, store description contradicts current build

## Anti-Sycophancy

Forbidden:
- ❌ "Great release!"
- ❌ "Players will appreciate these changes"

Instead: "12 changes documented. 3 balance changes need designer intent explanations before publishing."

## Completion Summary

```
Documentation:
  Patch notes: [written / updated]
  Internal changelog: [written / updated]
  Docs swept: ___/___ up to date
  STATUS: DONE / DONE_WITH_CONCERNS

  Next Step:
    PRIMARY: /game-retro — docs done, run retrospective
```

## Save Artifact

```bash
_DATETIME=$(date +%Y%m%d-%H%M%S)
echo "Saving to: $_PROJECTS_DIR/${_USER}-${_BRANCH}-release-docs-${_DATETIME}.md"
```

Write to `$_PROJECTS_DIR/{user}-{branch}-release-docs-{datetime}.md`. Supersedes prior if exists.

Discoverable by: /game-ship

## Review Log

```bash
[ -n "$_GG_BIN" ] && "$_GG_BIN/gstack-review-log" '{"skill":"game-docs","timestamp":"TIMESTAMP","status":"STATUS","version":"VERSION","commit":"COMMIT"}' 2>/dev/null || true
```
