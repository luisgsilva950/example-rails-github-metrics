# frozen_string_literal: true

module Planning
  class BurndownEntriesController < BaseController
    def create
      @cycle = Cycle.find(params[:cycle_id])
      @entry = BurndownEntry.new(entry_params)

      if @entry.save
        render json: @entry, status: :created
      else
        render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      @entry = BurndownEntry.find(params[:id])

      if @entry.update(entry_params)
        render json: @entry
      else
        render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @entry = BurndownEntry.find(params[:id])
      @entry.destroy
      head :no_content
    end

    private

    def entry_params
      params.require(:burndown_entry).permit(:deliverable_id, :developer_id, :cycle_id, :date, :hours_burned, :note)
    end
  end
end
