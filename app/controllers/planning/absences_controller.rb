module Planning
  class AbsencesController < BaseController
    def create
      @developer = Developer.find(params[:developer_id])
      @absence = @developer.absences.new(absence_params)

      if @absence.save
        redirect_to planning_developer_path(@developer), notice: "Absence added."
      else
        redirect_to planning_developer_path(@developer), alert: @absence.errors.full_messages.join(", ")
      end
    end

    def destroy
      @developer = Developer.find(params[:developer_id])
      @absence = @developer.absences.find(params[:id])
      @absence.destroy
      redirect_to planning_developer_path(@developer), notice: "Absence removed."
    end

    private

    def absence_params
      params.require(:absence).permit(:start_date, :end_date, :reason)
    end
  end
end
