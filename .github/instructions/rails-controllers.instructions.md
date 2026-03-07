---
applyTo: "app/controllers/**"
description: "Use when editing Rails controllers. Covers thin-controller pattern, action structure, and delegation."
---
# Controller Conventions

- Controllers are **routers**, not business logic.
- Each action should have at most ~5 lines in the body.
- An action does: fetch/build resource → execute operation → respond.
- Use `before_action` for shared setup (find resource, authenticate).
- Never run complex queries directly in the controller. Delegate to model scopes or query objects.
- **A single instance variable passed to the view** (Sandi Metz rule #4).

```ruby
class Metrics::AuthorsController < ApplicationController
  def index
    result = AuthorsRanking.call(page: params[:page], size: params[:size])
    render json: result
  end
end
```

## What NOT to Do in Controllers

- Don't put business logic here — delegate to services.
- Don't run complex queries — use scopes or query objects.
- Don't pass multiple instance variables to views.
