module Planning
  class CyclesController < BaseController
    def index
      @cycles = Cycle.order(start_date: :desc)
    end

    def new
      @cycle = Cycle.new
    end

    def create
      @cycle = Cycle.new(cycle_params)

      if @cycle.save
        redirect_to planning_cycles_path, notice: "Cycle created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @cycle = Cycle.find(params[:id])
    end

    def update
      @cycle = Cycle.find(params[:id])

      if @cycle.update(cycle_params)
        redirect_to planning_cycles_path, notice: "Cycle updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def plan
      @cycle = Cycle.find(params[:id])
      load_plan_data
    end

    def sync_all_dates_to_jira
      cycle = Cycle.find(params[:id])
      data = build_cycle_sync_service.call(cycle: cycle)
      successes = data[:results].count { |r| r[:success] }
      failures = data[:total] - successes

      notice = "Synced #{successes}/#{data[:total]} deliverables to Jira."
      notice += " #{failures} failed." if failures > 0
      redirect_to plan_planning_cycle_path(cycle), notice: notice
    rescue StandardError => e
      redirect_to plan_planning_cycle_path(cycle), alert: "Jira sync error: #{e.message}"
    end

    def burndown
      cycle = Cycle.find(params[:id])
      deliverables = cycle.deliverables.includes(:deliverable_allocations, :burndown_entries)
      holiday_dates = Holiday.dates_between(cycle.start_date, cycle.end_date)
      builder = ::BuildBurndownData.new(query: ::BurndownQuery.new(holiday_dates: holiday_dates))

      data = deliverables.map do |d|
        result = builder.call(deliverable: d, cycle: cycle)
        { id: d.id, title: d.title, effort: d.total_effort_hours, **result }
      end

      render json: data
    end

    private

    def build_cycle_sync_service
      SyncCycleDatesToJira.new
    end

    def cycle_params
      params.require(:cycle).permit(:name, :start_date, :end_date)
    end

    def load_plan_data
      fix_data_inconsistencies
      @capacities = @cycle.developer_cycle_capacities
                         .includes(developer: :team)
                         .order("developers.name")
      @deliverables = @cycle.deliverables
                           .includes(:team, deliverable_allocations: { developer: :team })
                           .ordered
      @available_developers = Developer.includes(:team)
                                      .where.not(id: @capacities.select(:developer_id))
                                      .order(:name)
      @cycle_developers = @cycle.developers.order(:name)
      @developer_allocations = build_developer_allocations_map
      @developer_absences = build_developer_absences_map
      @holiday_dates = Holiday.dates_between(@cycle.start_date, @cycle.end_date)
      @operational_activities = @cycle.cycle_operational_activities
                                     .includes(:developer)
                                     .ordered
      @developer_operational_map = build_developer_operational_map
      @burndown_entries_set = build_burndown_entries_set
    end

    def fix_data_inconsistencies
      refresh_gross_hours
      FixCycleAllocations.new.call(cycle: @cycle)
      refresh_computed_hours
    end

    def refresh_gross_hours
      fresh = @cycle.gross_hours
      @cycle.developer_cycle_capacities.find_each do |cap|
        next if cap.gross_hours == fresh

        factor = cap.developer&.productivity_factor.to_f
        cap.update_columns(
          gross_hours: fresh,
          real_capacity: (fresh * factor).round(2)
        )
      end
    end

    def refresh_computed_hours
      DeliverableAllocation
        .joins(:deliverable)
        .where(deliverables: { cycle_id: @cycle.id })
        .find_each do |alloc|
          fresh_allocated = alloc.plannable_days * 8
          fresh_operational = alloc.operational_days * 8
          next if alloc.allocated_hours == fresh_allocated && alloc.operational_hours == fresh_operational

          alloc.update_columns(allocated_hours: fresh_allocated, operational_hours: fresh_operational)
        end
    end

    def build_developer_allocations_map
      allocs = DeliverableAllocation
        .joins(:deliverable)
        .where(deliverables: { cycle_id: @cycle.id })
        .select(:developer_id, :deliverable_id, :start_date, :end_date)

      allocs.each_with_object({}) do |a, map|
        (map[a.developer_id] ||= []) << {
          deliverable_id: a.deliverable_id,
          start_date: a.start_date.to_s,
          end_date: a.end_date.to_s
        }
      end
    end

    def build_developer_absences_map
      developer_ids = @capacities.map(&:developer_id)
      absences = Absence
        .where(developer_id: developer_ids)
        .where("start_date <= ? AND end_date >= ?", @cycle.end_date, @cycle.start_date)

      absences.each_with_object({}) do |a, map|
        (map[a.developer_id] ||= []) << a
      end
    end

    def build_developer_operational_map
      activities = @operational_activities
      developer_ids = @capacities.map(&:developer_id)

      developer_ids.each_with_object({}) do |dev_id, map|
        applicable = activities.select { |a| a.developer_id.nil? || a.developer_id == dev_id }
        map[dev_id] = applicable
      end
    end

    def build_burndown_entries_set
      deliverable_ids = @deliverables.map(&:id)
      deliverable_entries = BurndownEntry.where(deliverable_id: deliverable_ids)
      operational_entries = BurndownEntry.where(cycle: @cycle).where.not(developer_id: nil)

      (deliverable_entries + operational_entries).each_with_object({}) do |entry, set|
        key = entry.deliverable_id.present? ? "#{entry.deliverable_id}-#{entry.developer_id}-#{entry.date}" : "#{entry.developer_id}-#{entry.date}"
        set[key] = entry
      end
    end
  end
end
