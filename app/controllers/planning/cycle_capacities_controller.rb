module Planning
  class CycleCapacitiesController < BaseController
    def create
      @cycle = Cycle.find(params[:cycle_id])
      @capacity = @cycle.developer_cycle_capacities.build(capacity_params)
      @capacity.real_capacity = compute_real_capacity(@capacity)

      if @capacity.save
        redirect_to plan_planning_cycle_path(@cycle), notice: "Developer added to cycle."
      else
        redirect_to plan_planning_cycle_path(@cycle), alert: @capacity.errors.full_messages.join(", ")
      end
    end

    def add_all
      @cycle = Cycle.find(params[:cycle_id])
      added = add_available_developers

      redirect_to plan_planning_cycle_path(@cycle),
                  notice: "#{added} developer(s) added to cycle."
    end

    def destroy
      @capacity = DeveloperCycleCapacity.find(params[:id])
      cycle = @capacity.cycle
      @capacity.destroy
      redirect_to plan_planning_cycle_path(cycle), notice: "Developer removed from cycle."
    end

    private

    def capacity_params
      params.require(:developer_cycle_capacity).permit(
        :developer_id, :gross_hours
      )
    end

    def compute_real_capacity(capacity)
      gross = capacity.gross_hours.to_f
      factor = capacity.developer&.productivity_factor.to_f
      (gross * factor).round(2)
    end

    def add_available_developers
      existing_ids = @cycle.developer_cycle_capacities.pluck(:developer_id)
      developers = Developer.where.not(id: existing_ids)
      gross = @cycle.gross_hours

      developers.count do |dev|
        cap = @cycle.developer_cycle_capacities.build(
          developer: dev,
          gross_hours: gross
        )
        cap.real_capacity = compute_real_capacity(cap)
        cap.save
      end
    end
  end
end
