---
applyTo: "app/models/**"
description: "Use when editing Rails models. Covers validations, associations, scopes, and callback conventions."
---

# Model Conventions

- Keep models thin. Validations, associations, and scopes belong here.
- **Always prefer model validations.** If a constraint can be expressed as a validation, it must live in the model — not in a service, controller, or callback.
- Extract business logic to Services.
- Callbacks (`before_save`, `after_create`) should be simple with no complex side effects. If a callback does anything beyond preparing the record's own data, move it to a Service.
- Scopes should be composable and reusable.

```ruby
class JiraBug < ApplicationRecord
  validates :issue_key, :title, :opened_at, presence: true
  validates :issue_key, uniqueness: true

  scope :recent, -> { where("opened_at >= ?", 30.days.ago) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
end
```

## What NOT to Do in Models

- Don't validate in services what the model should validate.
- Don't put business logic in callbacks — move to services.
- Don't use concerns used by a single class — inline the logic.
