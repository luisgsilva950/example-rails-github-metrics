# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sonar::Dashboard", type: :request do
  describe "GET /sonar" do
    it "renders the dashboard" do
      get "/sonar"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sonar Metrics")
    end

    it "displays projects when present" do
      create(:sonar_project, name: "my-api-service", bugs: 3, coverage: 85.2)

      get "/sonar"

      expect(response.body).to include("my-api-service")
      expect(response.body).to include("85.2")
    end

    it "shows empty state when no projects" do
      get "/sonar"

      expect(response.body).to include("No projects synced yet")
    end

    it "displays summary cards with aggregated metrics" do
      create(:sonar_project, bugs: 5, vulnerabilities: 2, code_smells: 10, coverage: 80.0)
      create(:sonar_project, bugs: 3, vulnerabilities: 1, code_smells: 5, coverage: 60.0)

      get "/sonar"

      expect(response.body).to include("8")  # total bugs
      expect(response.body).to include("3")  # total vulnerabilities
    end

    it "displays the sync toggle" do
      get "/sonar"

      expect(response.body).to include("Auto-sync from SonarCloud")
      expect(response.body).to include("sonar_metrics")
    end

    it "shows filter buttons" do
      create(:sonar_project)

      get "/sonar"

      expect(response.body).to include("All")
      expect(response.body).to include("Critical Only")
    end

    context "open vs resolved statistics" do
      it "counts all severities when All filter is active" do
        project = create(:sonar_project)
        create(:sonar_issue, sonar_project: project, severity: "MAJOR", status: "OPEN")
        create(:sonar_issue, sonar_project: project, severity: "MINOR", status: "OPEN")
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", status: "CLOSED")

        get "/sonar"

        expect(response.body).to include(">Open<")
        expect(response.body).to include(">Resolved<")
        expect(response.body).not_to include("Critical/Blocker")
      end

      it "counts only critical/blocker when Critical filter is active" do
        project = create(:sonar_project)
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", status: "OPEN")
        create(:sonar_issue, sonar_project: project, severity: "BLOCKER", status: "CLOSED")
        create(:sonar_issue, sonar_project: project, severity: "MAJOR", status: "OPEN")

        get "/sonar", params: { severity: "CRITICAL" }

        expect(response.body).to include("Open (Critical/Blocker)")
        expect(response.body).to include("Resolved (Critical/Blocker)")
      end
    end

    it "links the open card to the opened breakdown page" do
      create(:sonar_project)

      get "/sonar"

      expect(response.body).to include(sonar_opened_path)
    end
  end

  describe "GET /sonar/opened" do
    it "renders the opened breakdown page" do
      get "/sonar/opened"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Open Issues")
    end

    it "shows rule, description, repos count, and issue count" do
      project_a = create(:sonar_project, name: "alpha-service")
      project_b = create(:sonar_project, name: "beta-service")
      create(:sonar_issue, sonar_project: project_a, status: "OPEN", rule: "java:S1234", message: "Null pointer issue", issue_key: "K1")
      create(:sonar_issue, sonar_project: project_b, status: "OPEN", rule: "java:S1234", message: "Null pointer issue", issue_key: "K2")
      create(:sonar_issue, sonar_project: project_a, status: "OPEN", rule: "java:S5678", message: "Unused import", issue_key: "K3")

      get "/sonar/opened"

      expect(response.body).to include("java:S1234")
      expect(response.body).to include("java:S5678")
      expect(response.body).to include("Null pointer issue")
      expect(response.body).to include("Unused import")
      expect(response.body).to include("Description")
      expect(response.body).to include("Repos")
    end

    it "shows the number of affected repositories per rule" do
      project_a = create(:sonar_project, name: "alpha-service")
      project_b = create(:sonar_project, name: "beta-service")
      create(:sonar_issue, sonar_project: project_a, status: "OPEN", rule: "java:S1234", component: "alpha:src/Foo.java", issue_key: "R1")
      create(:sonar_issue, sonar_project: project_b, status: "OPEN", rule: "java:S1234", component: "beta:src/Bar.java", issue_key: "R2")
      create(:sonar_issue, sonar_project: project_a, status: "OPEN", rule: "java:S5678", component: "alpha:src/Baz.java", issue_key: "R3")

      get "/sonar/opened"

      body = response.body
      expect(body).to include("alpha-service")
      expect(body).to include("beta-service")
      expect(body).to include("src/Foo.java")
      expect(body).to include("src/Bar.java")
    end

    it "orders rules by count descending" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project, status: "OPEN", rule: "java:S1000", issue_key: "A1")
      create(:sonar_issue, sonar_project: project, status: "OPEN", rule: "java:S2000", issue_key: "B1")
      create(:sonar_issue, sonar_project: project, status: "OPEN", rule: "java:S2000", issue_key: "B2")

      get "/sonar/opened"

      body = response.body
      expect(body.index("java:S2000")).to be < body.index("java:S1000")
    end

    it "excludes resolved issues from the count" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project, status: "OPEN", rule: "java:S1234")
      create(:sonar_issue, sonar_project: project, status: "CLOSED", rule: "java:S1234")

      get "/sonar/opened"

      expect(response.body).to include(">1<")
    end

    it "shows empty state when no open issues" do
      get "/sonar/opened"

      expect(response.body).to include("No open issues found")
    end

    it "displays total open count in the badge" do
      project = create(:sonar_project)
      create(:sonar_issue, sonar_project: project, status: "OPEN", rule: "java:S1", issue_key: "X1")
      create(:sonar_issue, sonar_project: project, status: "OPEN", rule: "java:S2", issue_key: "X2")

      get "/sonar/opened"

      expect(response.body).to include(">2<")
    end

    context "with severity=CRITICAL filter" do
      it "shows only critical/blocker rules" do
        project = create(:sonar_project)
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", status: "OPEN", rule: "java:S9999", issue_key: "C1")
        create(:sonar_issue, sonar_project: project, severity: "MAJOR", status: "OPEN", rule: "java:S1111", issue_key: "M1")

        get "/sonar/opened", params: { severity: "CRITICAL" }

        expect(response.body).to include("Critical/Blocker")
        expect(response.body).to include("java:S9999")
        expect(response.body).not_to include("java:S1111")
      end
    end
  end

  describe "GET /sonar" do
    context "with severity=CRITICAL filter" do
      it "shows only projects with critical issues" do
        critical_project = create(:sonar_project, name: "critical-api")
        clean_project = create(:sonar_project, name: "clean-api")
        create(:sonar_issue, sonar_project: critical_project, severity: "CRITICAL", issue_type: "BUG")
        create(:sonar_issue, sonar_project: clean_project, severity: "MAJOR", issue_type: "BUG")

        get "/sonar", params: { severity: "CRITICAL" }

        expect(response.body).to include("critical-api")
        expect(response.body).not_to include("clean-api")
      end

      it "displays critical issue counts in summary cards" do
        project = create(:sonar_project, name: "my-project")
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_type: "BUG", issue_key: "C1")
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_type: "BUG", issue_key: "C2")
        create(:sonar_issue, sonar_project: project, severity: "MAJOR", issue_type: "BUG", issue_key: "M1")

        get "/sonar", params: { severity: "CRITICAL" }

        expect(response.body).to include("Critical Bugs")
        expect(response.body).to include("Critical Vulnerabilities")
      end

      it "shows total critical count per project in the table" do
        project = create(:sonar_project, name: "my-project")
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_type: "BUG", issue_key: "C1")
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_type: "VULNERABILITY", issue_key: "C2")

        get "/sonar", params: { severity: "CRITICAL" }

        expect(response.body).to include("Total Critical")
      end

      it "excludes closed/resolved issues from critical counts" do
        project = create(:sonar_project, name: "filtered-project")
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_type: "BUG", status: "OPEN")
        create(:sonar_issue, sonar_project: project, severity: "CRITICAL", issue_type: "BUG", status: "CLOSED")

        get "/sonar", params: { severity: "CRITICAL" }

        expect(response.body).to include("filtered-project")
        expect(response.body).to include("Critical Bugs")
      end

      it "includes BLOCKER severity issues in the critical section" do
        project = create(:sonar_project, name: "blocker-project")
        create(:sonar_issue, sonar_project: project, severity: "BLOCKER", issue_type: "BUG", status: "OPEN")

        get "/sonar", params: { severity: "CRITICAL" }

        expect(response.body).to include("blocker-project")
      end
    end
  end
end
