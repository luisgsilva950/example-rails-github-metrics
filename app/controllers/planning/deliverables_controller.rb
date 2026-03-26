module Planning
  class DeliverablesController < BaseController
    def index
      @deliverables = Deliverable.includes(:team, :cycle).ordered
      @deliverables = @deliverables.by_status(params[:status]) if params[:status].present?
      @deliverables = @deliverables.by_stack(params[:stack]) if params[:stack].present?
    end

    def new
      @deliverable = Deliverable.new
      @teams = Team.order(:name)
      @cycles = Cycle.order(start_date: :desc)
    end

    def create
      @deliverable = Deliverable.new(deliverable_params)

      if @deliverable.save
        redirect_to planning_deliverables_path, notice: "Deliverable created successfully."
      else
        @teams = Team.order(:name)
        @cycles = Cycle.order(start_date: :desc)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @deliverable = Deliverable.find(params[:id])
      @teams = Team.order(:name)
      @cycles = Cycle.order(start_date: :desc)
    end

    def update
      @deliverable = Deliverable.find(params[:id])

      if @deliverable.update(deliverable_params)
        redirect_to planning_deliverables_path, notice: "Deliverable updated successfully."
      else
        @teams = Team.order(:name)
        @cycles = Cycle.order(start_date: :desc)
        render :edit, status: :unprocessable_entity
      end
    end

    def sync_dates_to_jira
      deliverable = Deliverable.find(params[:id])
      result = build_sync_service.call(deliverable: deliverable)

      if result[:success]
        redirect_to edit_planning_deliverable_path(deliverable),
                    notice: "Dates synced to Jira issue #{result[:issue_key]}."
      else
        redirect_to edit_planning_deliverable_path(deliverable),
                    alert: "Failed to sync dates: #{result[:error]}"
      end
    rescue StandardError => e
      redirect_to edit_planning_deliverable_path(deliverable),
                  alert: "Jira sync error: #{e.message}"
    end

    private

    def build_sync_service
      SyncDatesToJira.new
    end

    def deliverable_params
      params.require(:deliverable).permit(
        :team_id, :cycle_id, :title, :jira_link,
        :specific_stack, :total_effort_hours, :priority, :status,
        :deliverable_type
      )
    end
  end
end
