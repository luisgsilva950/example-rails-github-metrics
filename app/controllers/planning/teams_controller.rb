module Planning
  class TeamsController < BaseController
    def index
      @teams = Team.order(:name)
    end

    def new
      @team = Team.new
    end

    def create
      @team = Team.new(team_params)

      if @team.save
        redirect_to planning_teams_path, notice: "Team created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @team = Team.find(params[:id])
    end

    def update
      @team = Team.find(params[:id])

      if @team.update(team_params)
        redirect_to planning_teams_path, notice: "Team updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def team_params
      params.require(:team).permit(:name)
    end
  end
end
