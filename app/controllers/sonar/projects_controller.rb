module Sonar
  class ProjectsController < BaseController
    def show
      @project = SonarProject.find(params[:id])
      @issues = apply_filters(@project.sonar_issues)
    end

    def sync_issues
      project = SonarProject.find(params[:id])
      SyncSonarIssues.new.call(project: project)

      redirect_to sonar_project_path(project),
                  notice: "Issues synced for #{project.name}."
    end

    private

    def apply_filters(scope)
      scope = scope.where(issue_type: params[:type]) if params[:type].present?
      scope = scope.where(severity: params[:severity]) if params[:severity].present?
      scope.order(creation_date: :desc)
    end
  end
end
