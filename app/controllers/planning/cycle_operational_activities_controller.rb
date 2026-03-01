module Planning
  class CycleOperationalActivitiesController < BaseController
    def create
      @cycle = Cycle.find(params[:cycle_id])

      if recurring_mode?
        create_recurring
      else
        create_single
      end
    end

    def destroy
      @cycle = Cycle.find(params[:cycle_id])
      @activity = @cycle.cycle_operational_activities.find(params[:id])
      @activity.destroy
      redirect_to plan_planning_cycle_path(@cycle, anchor: "operational-activities"),
                  notice: "Operational activity removed."
    end

    private

    def create_single
      @activity = @cycle.cycle_operational_activities.new(activity_params)

      if @activity.save
        redirect_to plan_planning_cycle_path(@cycle, anchor: "operational-activities"),
                    notice: "Operational activity added."
      else
        redirect_to plan_planning_cycle_path(@cycle, anchor: "operational-activities"),
                    alert: @activity.errors.full_messages.join(", ")
      end
    end

    def create_recurring
      dates = recurring_dates
      if dates.empty?
        redirect_to plan_planning_cycle_path(@cycle, anchor: "operational-activities"),
                    alert: "No matching weekdays found in the cycle."
        return
      end

      attrs = activity_params.except(:start_date, :end_date)
      records = dates.map { |d| @cycle.cycle_operational_activities.new(attrs.merge(start_date: d, end_date: d)) }
      invalid = records.reject(&:valid?)

      if invalid.any?
        redirect_to plan_planning_cycle_path(@cycle, anchor: "operational-activities"),
                    alert: invalid.first.errors.full_messages.join(", ")
      else
        records.each(&:save!)
        redirect_to plan_planning_cycle_path(@cycle, anchor: "operational-activities"),
                    notice: "#{records.size} recurring operational activities added."
      end
    end

    def recurring_mode?
      params.dig(:cycle_operational_activity, :recurrence_day).present?
    end

    def recurring_dates
      wday = params.dig(:cycle_operational_activity, :recurrence_day).to_i
      (@cycle.start_date..@cycle.end_date).select { |d| d.wday == wday }
    end

    def activity_params
      params.require(:cycle_operational_activity)
            .permit(:name, :developer_id, :start_date, :end_date)
    end
  end
end
