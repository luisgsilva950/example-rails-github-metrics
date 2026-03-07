---
applyTo: "**/*.rb"
description: "Use when editing any Ruby file. Covers Sandi Metz rules, naming conventions, confident code patterns, RuboCop compliance, and anti-patterns."
---

# Ruby Style Rules

## Sandi Metz's Rules

1. **Classes with no more than 100 lines.**
2. **Methods with no more than 5 lines.**
3. **Methods receive no more than 4 parameters** (hash options counts as 1).
4. **Controllers: a single instance variable passed to the view.**

When a rule needs to be broken, require an explicit justification in a code comment.

## Naming

- Classes: nouns or `VerbSubject` for services (`ExtractMetrics`, `SyncJiraBugs`).
- Methods: descriptive verbs. `calculate_total`, `normalize`, `process`.
- Variables: descriptive. Avoid abbreviations. `author_name` instead of `an`.
- Scopes: descriptive and composable. `recent`, `by_status`, `merged`.
- Avoid `get_`/`set_` prefixes. Ruby doesn't use them.

## Confident Code (Avdi Grimm)

### Handle inputs at the boundary

Convert and validate data as early as possible. Inside the system, trust that data is correct.

```ruby
# Good: convert at the entry point
def call(name)
  name = name.to_s.strip
  return nil if name.empty?

  normalize(name)
end
```

### Never return nil silently

If an operation can fail, be explicit. Use exceptions for exceptional errors, `NullObject` pattern for expected absence, or return a default value.

### Guard clauses instead of nested if/else

```ruby
# Good
def process(record)
  return unless record.valid?
  return if record.processed?

  execute(record)
end
```

## RuboCop

- **All code must pass `bin/rubocop` with zero offenses.**
- **Prefer double-quoted strings** (`"hello"`).
- **Never disable RuboCop rules** without an explicit, justified comment.
- When RuboCop and other guides conflict, **RuboCop wins**.

## What NOT to Do

- Don't create premature abstractions — wait for 3 cases (Rule of Three).
- Don't use concerns to hide complexity used by a single class.
- Don't create God Objects (classes > 100 lines → split).
- Don't put business logic in controllers or callbacks.
- Don't use `rescue Exception` — use `rescue StandardError` or specific exceptions.
- Don't silence errors. Log at minimum. Prefer to fail loudly.
- Don't use metaprogramming unless the benefit is very clear and readable.
