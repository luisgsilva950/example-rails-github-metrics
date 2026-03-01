module Planning
  class CycleAllocationsController < BaseController
    def create
      @cycle = Cycle.find(params[:cycle_id])
      @allocation = DeliverableAllocation.new(allocation_params)

      anchor = "deliverable-#{allocation_params[:deliverable_id]}"

      if @allocation.save
        respond_to do |format|
          format.html { redirect_to plan_planning_cycle_path(@cycle, anchor: anchor), notice: "Developer allocated to deliverable." }
          format.json { render json: { ok: true } }
        end
      else
        respond_to do |format|
          format.html { redirect_to plan_planning_cycle_path(@cycle, anchor: anchor), alert: @allocation.errors.full_messages.join(", ") }
          format.json { render json: { error: @allocation.errors.full_messages.join(", ") }, status: :unprocessable_entity }
        end
      end
    end

    def update
      @cycle = Cycle.find(params[:cycle_id])
      @allocation = DeliverableAllocation.find(params[:id])

      anchor = "deliverable-#{@allocation.deliverable_id}"

      if @allocation.update(allocation_params)
        respond_to do |format|
          format.html { redirect_to plan_planning_cycle_path(@cycle, anchor: anchor), notice: "Allocation updated." }
          format.json { render json: { ok: true } }
        end
      else
        respond_to do |format|
          format.html { redirect_to plan_planning_cycle_path(@cycle, anchor: anchor), alert: @allocation.errors.full_messages.join(", ") }
          format.json { render json: { error: @allocation.errors.full_messages.join(", ") }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @allocation = DeliverableAllocation.find(params[:id])
      cycle = Cycle.find(params[:cycle_id])
      anchor = "deliverable-#{@allocation.deliverable_id}"
      @allocation.destroy
      redirect_to plan_planning_cycle_path(cycle, anchor: anchor), notice: "Allocation removed."
    end

    private

    def allocation_params
      params.require(:deliverable_allocation).permit(
        :deliverable_id, :developer_id, :start_date, :end_date
      )
    end
  end
end
