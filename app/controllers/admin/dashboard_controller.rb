module Admin
  class DashboardController < BaseController
    def index
      @model_registry = MODEL_REGISTRY
    end
  end
end
