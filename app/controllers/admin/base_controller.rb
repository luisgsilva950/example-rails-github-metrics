require "digest"

module Admin
  class BaseController < ApplicationController
    layout "application"

    before_action :require_basic_auth

    MODEL_REGISTRY = {
      "repositories" => Repository,
      "commits" => Commit,
      "pull_requests" => PullRequest,
      "jira_bugs" => JiraBug
    }.freeze

    private

    def require_basic_auth
      username = ENV["ADMIN_USERNAME"].presence || "admin"
      password = ENV["ADMIN_PASSWORD"].presence || "changeme"

      authenticate_or_request_with_http_basic("Admin Console") do |provided_user, provided_pass|
        secure_compare(provided_user, username) &&
          secure_compare(provided_pass, password)
      end
    end

    def secure_compare(a, b)
      lhs = Digest::SHA256.hexdigest(a.to_s)
      rhs = Digest::SHA256.hexdigest(b.to_s)
      ActiveSupport::SecurityUtils.secure_compare(lhs, rhs)
    end
  end
end
