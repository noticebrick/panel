# Patch Workflow Rules

These rules are mandatory for this repository.

## 1) Do Not Manually Edit Patch Files
- Do not hand-edit files under `patches/*.patch`.
- Exception: only if explicitly requested by the repo owner for emergency recovery.

## 2) Generate Patches Only From `source`
- Always generate patch files from `panel/source` changes.
- Use the project workflow (`tool.sh`) or equivalent `git diff` generation from `source`.
- Do not regenerate from partial file subsets unless explicitly requested.
- Include new/untracked files in generated patches:
  - Do not rely on plain `git diff HEAD` for patch generation.
  - Preferred flow:
    1. `git -C source add -A`
    2. `git -C source diff --cached --binary HEAD -- > patches/<name>.patch`
  - Reason: plain `git diff HEAD` omits untracked files and can silently drop `/dev/null` add-file hunks.

## 3) Preserve Reproducibility
- Patch creation should be deterministic and reproducible.
- Prefer replacing the whole patch by regeneration, not line-by-line surgery.

## 4) Required Validation Before Release
Run all checks below before publishing a release artifact:

1. `git -C source apply --check patches/0001-filemanager-pagination.patch`
2. `git -C source apply --check patches/0002-zhtw-localization.patch`

## 5) Temporary Test Changes
- Any testing-only workflow/script modifications must be reverted before final commit.
- Do not keep test-only CI guardrails unless explicitly approved for permanent adoption.

## 6) Incident Rule
- If a release artifact contains parse errors or truncated files, stop release publication.
- Regenerate patches from `source`, re-run validations, and only then publish.
