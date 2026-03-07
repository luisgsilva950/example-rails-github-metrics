---
applyTo: "app/services/**"
description: "Use when editing Rails services. Covers single-responsibility services, dependency injection, VerbSubject naming, and DIP."
---
# Service Conventions

- One class, one public method: `call`.
- Descriptive name in `VerbSubject` format: `ExtractMetrics`, `NormalizeAuthorName`, `SyncJiraBugs`.
- Receive dependencies in the constructor (keyword args with defaults), operation data in `call`.
- Return a simple result (object, hash, or Result pattern if needed).

```ruby
class NormalizeAuthorName
  def initialize(mappings: AuthorNameMappings.new)
    @mappings = mappings
  end

  def call(name)
    return nil if name.nil?

    canonical = @mappings.find(name)
    (canonical || name).strip.downcase
  end
end
```

## Dependency Inversion (DIP)

1. **Services receive all collaborators in the constructor** via keyword arguments with sensible defaults.
2. **Never call `.new` on collaborator classes inside a service.** If a service needs another service, inject it.
3. **Controllers wire dependencies** — they are the composition root.
4. **Tests benefit directly** — inject fakes/stubs at construction time.

```ruby
# Good: defaults make production wiring easy, tests can inject fakes
class SyncJiraBugs
  def initialize(client: JiraClient.new, normalizer: CategoriesNormalizer.new)
    @client = client
    @normalizer = normalizer
  end

  def call(jql:)
    issues = @client.call(jql: jql)
    issues.each { |issue| @normalizer.call(issue) }
  end
end
```

## What NOT to Do in Services

- Don't validate what the model should validate.
- Don't call `.new` on collaborators inside the service body.
- Don't create services with multiple public methods.
