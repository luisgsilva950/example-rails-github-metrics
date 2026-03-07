---
applyTo: "app/queries/**"
description: "Use when editing query objects. Covers query object pattern, relation injection, and composability."
---
# Query Object Conventions

When a query is too complex for a scope, extract it into a Query Object.

- One class, one public method: `call`.
- Receive a base relation in the constructor (default to `Model.all`).
- Return an ActiveRecord relation when possible (composability).

```ruby
class AuthorsRankingQuery
  def initialize(relation: Commit.all)
    @relation = relation
  end

  def call(page:, size:)
    @relation
      .where.not(normalized_author_name: [nil, ""])
      .group(:normalized_author_name)
      .select("normalized_author_name AS author", "COUNT(*) AS total_commits")
      .order("total_commits DESC")
      .limit(size)
      .offset((page - 1) * size)
  end
end
```
