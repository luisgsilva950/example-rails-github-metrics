# frozen_string_literal: true

class Metrics::SupportTicketsController < ApplicationController
  def index
    apply_default_filters

    @jira_base_url = jira_base_url
    @statuses = SupportTicket.distinct.order(:status).pluck(:status).compact
    @priorities = SupportTicket.distinct.order(:priority).pluck(:priority).compact

    scope = SupportTicket.all
    scope = scope.by_team(@team) if @team.present?
    scope = scope.by_date_range(@start_date, @end_date)

    result = SupportTickets::ListByTeam.new(jira_base_url: jira_base_url).call(
      scope: scope,
      filters: { status: @status, priority: @priority }
    )

    @tickets = result[:tickets]
    @total = result[:total]
  end

  def clone_to_bugs
    ids = Array(params[:ticket_ids]).map(&:to_i)
    bugs = SupportTickets::CloneToBugs.new.call(ticket_ids: ids)

    redirect_to metrics_support_tickets_path(request.query_parameters),
      notice: "#{bugs.size} ticket(s) cloned to bugs."
  end

  private

  def jira_base_url
    ENV.fetch("JIRA_SITE", "https://digitial-product-engineering.atlassian.net")
  end

  def apply_default_filters
    today = Time.current.in_time_zone(SupportTicket::SAO_PAULO_TZ).to_date
    @team = params[:team].presence || "Digital Farm"
    @start_date = params[:start_date].presence || today.beginning_of_year.iso8601
    @end_date = params[:end_date].presence || today.iso8601
    @status = params[:status].presence
    @priority = params[:priority].presence
  end
end
