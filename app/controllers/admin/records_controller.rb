module Admin
  class RecordsController < BaseController
    before_action :set_model

    def index
      scope = @model.order(created_at: :desc)
      @columns = @model.column_names
      @supports_name_filter = @columns.include?("name")
      @supports_normalized_author_filter = commit_model? && @columns.include?("normalized_author_name")
      @normalized_author_options = []

      if @supports_name_filter && params[:q].present?
        query = "%#{params[:q].strip}%"
        scope = scope.where(@model.arel_table[:name].matches(query))
      end

      if @supports_normalized_author_filter
        @normalized_author_options = @model.distinct.where.not(normalized_author_name: nil).order(:normalized_author_name).pluck(:normalized_author_name)

        if params[:normalized_author_names].present?
          selected_authors = Array(params[:normalized_author_names]).reject(&:blank?)
          scope = scope.where(normalized_author_name: selected_authors) if selected_authors.any?
        end
      end

      @records = scope.limit(50)
    end

    def show
      @record = @model.find(params[:id])
    end

    private

    def set_model
      key = params[:model].to_s
      @model = MODEL_REGISTRY[key]
      raise ActiveRecord::RecordNotFound, "Unknown model" unless @model
    end

    def commit_model?
      @model == Commit
    end
  end
end
