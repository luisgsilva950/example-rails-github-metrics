---
description: "Use when refactoring, designing new classes, discussing architecture, applying SOLID principles, or reviewing code structure. Covers SRP, OCP, LSP, ISP, DIP, and composition over inheritance."
---
# SOLID & Design Principles

## Single Responsibility Principle (SRP)

Each class does **one thing only**. If you need "and" to describe it, split it.

- Models: validations, associations, scopes. Nothing more.
- Controllers: receive request, delegate, respond. Nothing more.
- Services: one business operation, one `call` method. Nothing more.
- Query Objects: one complex query. Nothing more.

```ruby
# Good: each class has a single reason to change
class FilterBugs        # responsibility: apply filters to a scope
class BuildTimeSeries   # responsibility: group data into time buckets
class SerializeBug      # responsibility: format a bug for JSON output
```

## Open/Closed Principle (OCP)

Open for extension, closed for modification. Add new classes instead of conditionals.

```ruby
# Good: extend via new classes
class WeeklyBucket
  def call(time) = time.beginning_of_week(:monday).strftime("%Y-%m-%d")
end

class MonthlyBucket
  def call(time) = time.strftime("%Y-%m")
end

# Bad: growing case statement
def time_bucket(time)
  case @group_by
  when "daily" then ...
  when "weekly" then ...
  end
end
```

## Liskov Substitution Principle (LSP)

Respect the duck typing contract: objects responding to the same interface must behave consistently.

```ruby
class JiraClient
  def call(jql:) = # returns array of issues
end

class FakeJiraClient
  def call(jql:) = # returns array of test issues
end
```

## Interface Segregation Principle (ISP)

Keep interfaces small and focused. Depend only on the methods you use.

```ruby
# Good: depends only on `call`
class SyncJiraBugs
  def initialize(client:)
    @client = client
  end
end
```

## Dependency Inversion Principle (DIP)

Always inject dependencies via constructor. Never instantiate collaborators internally.

```ruby
# Good: depends on abstraction
class MetricsExtractor
  def initialize(client:, configuration:)
    @client = client
    @configuration = configuration
  end

  def call
    data = @client.fetch_metrics
    @configuration.apply(data)
  end
end
```

## Composition over Inheritance

Build behavior by composing small, focused objects. Use inheritance only for Rails framework classes (`ApplicationController`, `ApplicationRecord`).

```ruby
# Good: compose small objects
class BuildBugsReport
  def initialize(filter: FilterBugs.new, serializer: SerializeBug.new)
    @filter = filter
    @serializer = serializer
  end

  def call(scope:, params:)
    filtered = @filter.call(scope: scope, params: params)
    filtered.map { |bug| @serializer.call(bug) }
  end
end
```

## Eliminate Conditionals

Prefer guard clauses, polymorphism, hash lookups, or defaults over if/else.

```ruby
# Good: hash lookup
BUCKET_STRATEGIES = {
  "daily"   => DailyBucket,
  "weekly"  => WeeklyBucket,
  "monthly" => MonthlyBucket
}.freeze

def bucket_for(group_by)
  BUCKET_STRATEGIES.fetch(group_by)
end
```
