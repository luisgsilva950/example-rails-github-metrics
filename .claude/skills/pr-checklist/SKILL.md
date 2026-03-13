---
name: pr-checklist
description: "Run the PR readiness checklist before opening a pull request. Use when preparing a PR, reviewing code before merge, or validating compliance with project standards."
---

# PR Checklist

## When to Use

- Before opening a pull request
- After completing a feature or bug fix
- When reviewing your own code for compliance

## Procedure

1. Read the changed files using `git diff --name-only main`
2. For each changed file, verify these rules:

### Architecture & Design

- [ ] Does each class have a single responsibility?
- [ ] Classes under 100 lines?
- [ ] Methods under 5 lines?
- [ ] No `.new` calls on collaborators inside services (DIP)?
- [ ] New behavior added via new classes, not conditionals in existing ones (OCP)?
- [ ] Dependencies are injected, not hard-coded?

### Rails Conventions

- [ ] Controller actions with at most one instance variable?
- [ ] Business logic in services, not in controllers/models?
- [ ] Complex queries in scopes or query objects?
- [ ] Data integrity rules expressed as model validations, not service-level checks?
- [ ] Minimal `if/else` — guard clauses, polymorphism, or hash lookups used instead?

### Code Quality

- [ ] Names are clear and descriptive?
- [ ] No unnecessary mocks — real objects and real DB used in tests?
- [ ] `bin/rubocop` passes with zero offenses?

### Tests

- [ ] Tests (RSpec) cover the added/changed behavior?
- [ ] Integration tests for new endpoints?

3. Run `bin/rubocop` and report any offenses
4. Run `bundle exec rspec` for the affected spec files
5. Summarize findings with pass/fail per checklist item

## Output Format

Report each checklist item as PASS or FAIL with a brief explanation for any failures.
