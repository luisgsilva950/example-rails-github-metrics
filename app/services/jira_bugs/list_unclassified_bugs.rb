# frozen_string_literal: true

module JiraBugs
  # Finds bugs missing classification (no development_type or unknown components).
  # Returns a paginated result hash.
  class ListUnclassifiedBugs
    KNOWN_COMPONENTS = [
      "Ag Operations", "Catalog - Crop Protection", "Catalog - Crops",
      "Catalog - Fertilizer", "Catalog - Generic Items",
      "Catalog - Growth Scale and Stage", "Catalog - Seeds Varieties",
      "Custom Attributes", "Legacy Tasks", "Notes", "Weather",
      "My Cropwise", "CW Elements", "CW Farm Settings",
      "Farm Field Tree - Organization", "Farm Field Tree - Farm",
      "Farm Field Tree - Region", "Farm Field Tree - Crop Cycle",
      "Farm Field Tree - Crop Zone", "Farm Field Tree - Geometry",
      "Integration - Map Integrator", "Integration - Integration Core",
      "Account - User profile", "Account - Invite / Create users",
      "Account - Contact / Workers", "Account - User permission",
      "Account - Signin", "Account - Signup", "Account - Legal docs",
      "App - Plan / Entitlement",
      "App - Distribution Licensing / Access Key",
      "App - Apps / Credentials",
      "App - Campaign / Campaign Link / Access Key",
      "Workspace - Workspace creation", "Workspace - Contract / Quota",
      "Divisions", "Notification system - Emails"
    ].freeze

    def initialize(serializer: nil, jira_base_url:)
      @serializer = serializer || SerializeBug.new(jira_base_url: jira_base_url)
    end

    def call(scope:, page:, size:)
      scope = apply_unclassified_filter(scope)
      paginate(scope, page, size)
    end

    private

    def apply_unclassified_filter(scope)
      scope.where(development_type: nil)
           .or(scope.where.not("components && ARRAY[?]::varchar[]", KNOWN_COMPONENTS))
    end

    def paginate(scope, page, size)
      total = scope.count
      bugs = scope.order(opened_at: :desc)
                  .offset((page - 1) * size)
                  .limit(size)

      {
        content: bugs.map { |bug| @serializer.call(bug) },
        meta: { page: page, size: size, total: total, total_pages: (total.to_f / size).ceil }
      }
    end
  end
end
