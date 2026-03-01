module Planning
  class DevelopersController < BaseController
    def index
      @developers = Developer.includes(:team).order(:name)
      @developers = @developers.by_stack(params[:stack]) if params[:stack].present?
      @developers = @developers.by_seniority(params[:seniority]) if params[:seniority].present?
    end

    def show
      @developer = Developer.find(params[:id])
      load_allocations
      @absences = @developer.absences.order(start_date: :desc)
    end

    def new
      @developer = Developer.new
      @teams = Team.order(:name)
    end

    def create
      @developer = Developer.new(developer_params)

      if @developer.save
        redirect_to planning_developers_path, notice: "Developer created successfully."
      else
        @teams = Team.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @developer = Developer.find(params[:id])
      @teams = Team.order(:name)
    end

    def update
      @developer = Developer.find(params[:id])

      if @developer.update(developer_params)
        redirect_to planning_developer_path(@developer), notice: "Developer updated successfully."
      else
        @teams = Team.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def developer_params
      params.require(:developer).permit(
        :team_id, :name, :domain_stack,
        :seniority, :productivity_factor
      )
    end

    def load_allocations
      @allocations = DeliverableAllocation
        .includes(deliverable: %i[team cycle])
        .where(developer: @developer)
    end
  end
end
