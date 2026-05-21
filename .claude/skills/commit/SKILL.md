# /commit skill

Smart conventional-commit + PR description generator for MoodTune.

Stages only files relevant to the current change, enforces branch safety, and outputs a ready-to-use commit message and PR body.

---

## Instructions

### Step 1 — Branch safety check

Run `git branch --show-current`. If the result is `main` or `master`, STOP and tell the user:

> "You're on `{branch}`. Committing directly to main is blocked — please create a feature branch first."

Do not proceed past this step if on a protected branch.

---

### Step 2 — Inspect working tree

Run all of these in parallel:

1. `git status --short` — full picture of tracked + untracked changes
2. `git diff HEAD` — diff of all modified tracked files
3. `git log --oneline -8` — recent commits for style reference and scope context

Read the diff carefully. Identify:
- **What changed functionally** — new feature, bug fix, refactor, config, test, docs, chore
- **Which files are load-bearing** (contain the actual logic change) vs. incidental (generated, lockfile noise, unrelated edits)
- **The feature or domain touched** — map to a MoodTune feature area: `analysis`, `auth`, `spotify`, `upload`, `routing`, `core`, `l10n`, `di`, `ui`, or a cross-cutting area like `deps` / `ci` / `config`

---

### Step 3 — Select files to stage

Do **not** blindly `git add .`. Instead:

**Stage these:**
- Source files directly related to the change (`.dart`, `.py`, `.ts`, etc.)
- Test files that cover the changed code
- Config or schema files updated as part of this change
- `pubspec.yaml` / `pubspec.lock` if a dependency was intentionally added or updated
- New assets, ARB locale files, or generated files that are _part of this feature_

**Exclude (do not stage):**
- Unrelated files with incidental edits (opened but not meaningfully changed)
- `.env`, `.env.*`, `*.local` — never commit secrets
- IDE/editor files: `.idea/`, `.vscode/`, `*.iml`
- Auto-generated build artifacts unless the generator config itself changed
- `coverage/` output, `build/` directories
- Any file the user hasn't explicitly asked to include

If you're uncertain about a file, **ask before staging it** — surface it to the user with a one-line description of what it contains.

Stage each selected file explicitly by name:
```
git add path/to/file1.dart path/to/file2.dart ...
```

After staging, run `git diff --cached --stat` and show the user the staged file list for confirmation before committing.

---

### Step 4 — Generate conventional commit message

Format:
```
<type>(<scope>): <subject>

[optional body — 1–3 lines if the "why" isn't obvious]

Co-Authored-By: Claude Sonnet 4.7 <noreply@anthropic.com>
```

**Types:**
| Type | When to use |
|------|-------------|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `refactor` | Code restructure with no behaviour change |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Tooling, deps, CI, config |
| `style` | Formatting, lint, no logic change |
| `perf` | Performance improvement |
| `l10n` | Localization / ARB files |
| `revert` | Reverts a previous commit |

**Scope** — use the MoodTune feature area identified in Step 2 (e.g. `analysis`, `auth`, `spotify`, `upload`, `routing`, `core`, `l10n`, `di`, `ui`). Omit scope only for repo-wide changes.

**Subject rules:**
- Imperative mood: "add", "fix", "remove" — not "added" or "fixes"
- ≤ 72 characters including `type(scope): `
- No period at the end
- Describe the _what_, not the _how_

**Body rules (include only when needed):**
- Explain the _why_ or the non-obvious tradeoff
- Reference Linear issue if one is identifiable from branch name or recent commits (e.g. `Closes FUL-203`)
- Omit if the subject line is self-explanatory

---

### Step 5 — Generate PR description

Output a PR description the user can paste into GitHub. Use this template:

```markdown
## What

<!-- One paragraph: what this PR does and why it exists. -->

## Changes

<!-- Bullet list of the key files/components changed and what each does. -->
- `path/to/file.dart` — description
- ...

## How to test

<!-- Numbered steps to verify the change works. Be specific to MoodTune's stack:
     - `flutter run --flavor development --target lib/main_development.dart --dart-define-from-file=.env`
     - Navigate to X screen
     - Perform Y action
     - Expect Z result -->

## Checklist

- [ ] `flutter analyze` passes
- [ ] `very_good test --coverage` passes
- [ ] No `.env` or secrets staged
- [ ] PR targets a feature branch, not `main`
```

Fill in each section from what you know about the diff. Leave placeholders only where you genuinely cannot infer the answer.

---

### Step 6 — Commit

After the user confirms the staged files and commit message (or asks you to proceed), run:

```bash
git commit -m "$(cat <<'EOF'
<generated commit message here>
EOF
)"
```

Then run `git status` to confirm the commit landed cleanly.

**Do not push** unless the user explicitly asks.

---

## Output format

Present results to the user in this order:

1. **Branch** — confirm it's safe to proceed
2. **Staged files** — list with one-line rationale for each included/excluded decision
3. **Commit message** — formatted block, ready to copy
4. **PR description** — formatted markdown block, ready to paste into GitHub
5. **Confirm?** — ask for go-ahead before running the actual commit

If the user says "just do it" or similar, skip the confirmation and commit directly.
