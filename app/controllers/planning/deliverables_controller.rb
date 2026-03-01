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

    private

    def deliverable_params
      params.require(:deliverable).permit(
        :team_id, :cycle_id, :title, :jira_link,
        :specific_stack, :total_effort_hours, :priority, :status,
        :deliverable_type
      )
    end
  end
end
