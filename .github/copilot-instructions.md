# Project Guidelines

## Philosophy

This Rails project follows three core references:

- **Sandi Metz** — Small classes, single responsibility, simple OO code.
- **Avdi Grimm** — Confident code. Handle inputs early, fail explicitly, never return nil when an object is expected.
- **DHH** — Convention over Configuration. Use Rails as designed. Resist premature abstraction.

**Golden rule: simplicity above all.** If a solution feels complicated, it's probably wrong.

## Engineering Mindset

- Think like a principal engineer: choose the **simplest** solution that solves the problem.
- **Plan before you code.** Break non-trivial work into small steps first.
- **Prefer model validations** for data integrity — never duplicate in services.
- **Eliminate conditionals** — use guard clauses, polymorphism, hash lookups, or defaults.
- If you can't explain the solution in one sentence, it's too complex.

## Directory Structure

```
app/
  controllers/    # HTTP routing. Thin.
  models/         # ActiveRecord. Validations, associations, scopes.
  services/       # Business operations. One class = one `call`.
  queries/        # Query objects for complex queries.
  presenters/     # Presentation logic for views.
  helpers/        # Simple formatting for views.
  views/          # Templates. Zero logic.
  jobs/           # Background jobs. Delegate to services.
```

## Build & Test

- Run tests: `bundle exec rspec`
- Run linter: `bin/rubocop` (must pass with zero offenses)
- Auto-correct: `bin/rubocop -A`

## Detailed Guidelines

Specific instructions are loaded automatically based on the files you're editing:

- Ruby style rules → when editing `**/*.rb`
- Model conventions → when editing `app/models/**`
- Controller conventions → when editing `app/controllers/**`
- Service conventions → when editing `app/services/**`
- Query conventions → when editing `app/queries/**`
- Test conventions → when editing `spec/**`
- SOLID/design principles → loaded on-demand when refactoring or designing

Use `/pr-checklist` skill before opening a PR. Use `/rubocop-fix` skill for lint issues.
