---
applyTo: "spec/**"
description: "Use when editing or creating RSpec tests. Covers test conventions, structure, and mandatory test rules."
---
# RSpec Testing Conventions

## Mandatory Rule

**Every code change must have corresponding tests.** No exceptions. This includes new features, bug fixes, refactors, and any new service/model/controller/query.

## General Principles

- Test behavior, not implementation.
- A test should answer: "what happens when...?"
- Prefer **integration tests** that exercise the full stack.
- **No mocks by default.** Use real objects and real database interactions. Mocks only at hard external boundaries (third-party APIs).
- Use `let` and `let!` for setup. Prefer `FactoryBot` for test data.
- Keep tests independent — no reliance on execution order.

## Test Types (in order of preference)

1. **Request specs** — Full request-response cycle for controllers.
2. **Model specs** — Validations, associations, scopes.
3. **Service specs** — The `call` method with real dependencies.
4. **Query object specs** — Real database and real records.

## Structure

- Mirror `app/` structure: `spec/services/`, `spec/models/`, `spec/requests/`, `spec/queries/`.
- File name: `_spec.rb` suffix matching source file.
- Cover happy path and edge cases (nil, empty string, invalid data).

## Examples

### Service spec

```ruby
RSpec.describe NormalizeAuthorName do
  subject(:normalizer) { described_class.new }

  it "normalizes name to lowercase" do
    expect(normalizer.call("John Doe")).to eq("john doe")
  end

  it "returns nil for nil input" do
    expect(normalizer.call(nil)).to be_nil
  end
end
```

### Request spec

```ruby
RSpec.describe "Metrics::Authors", type: :request do
  describe "GET /metrics/authors" do
    it "returns a list of authors ranked by commits" do
      create(:commit, normalized_author_name: "jane doe")
      create(:commit, normalized_author_name: "jane doe")
      create(:commit, normalized_author_name: "john doe")

      get "/metrics/authors", params: { page: 1, size: 10 }

      expect(response).to have_http_status(:ok)
      expect(parsed_body.first["author"]).to eq("jane doe")
    end
  end
end
```
