---
name: rubocop-fix
description: "Run RuboCop to find and fix lint offenses. Use when there are style violations, before committing, or when asked to fix linting issues."
---

# RuboCop Fix

## When to Use

- Code has style violations or lint errors
- Before committing changes
- When asked to fix RuboCop offenses
- After generating or editing Ruby files

## Procedure

1. Run `bin/rubocop` to check for offenses
2. If there are auto-correctable offenses, run `bin/rubocop -A`
3. For remaining offenses that cannot be auto-corrected:
   - Read each offending file
   - Apply the fix manually following the project's RuboCop configuration
4. Run `bin/rubocop` again to confirm zero offenses
5. Report the final result

## Rules

- **Prefer double-quoted strings** (`"hello"`)
- **Never disable RuboCop rules** without an explicit, justified comment
- When RuboCop and other guides conflict, **RuboCop wins**
- The `.rubocop.yml` configuration is the authoritative source

## Output Format

Report the number of files inspected, offenses found, and offenses corrected. List any remaining issues that need manual attention.
