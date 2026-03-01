# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_28_210250) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "absences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "developer_id", null: false
    t.date "end_date", null: false
    t.string "reason"
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.index ["developer_id"], name: "index_absences_on_developer_id"
  end

  create_table "commits", force: :cascade do |t|
    t.string "author_name"
    t.datetime "committed_at"
    t.datetime "created_at", null: false
    t.text "message"
    t.string "normalized_author_name"
    t.bigint "repository_id", null: false
    t.string "sha"
    t.datetime "updated_at", null: false
    t.index ["committed_at"], name: "index_commits_on_committed_at"
    t.index ["normalized_author_name"], name: "index_commits_on_normalized_author_name"
    t.index ["repository_id", "committed_at"], name: "index_commits_on_repository_id_and_committed_at"
    t.index ["repository_id"], name: "index_commits_on_repository_id"
    t.index ["sha"], name: "index_commits_on_sha", unique: true
  end

  create_table "cycle_operational_activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "color", default: "#ef4444", null: false
    t.datetime "created_at", null: false
    t.uuid "cycle_id", null: false
    t.uuid "developer_id"
    t.date "end_date", null: false
    t.string "name", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.index ["cycle_id"], name: "index_cycle_operational_activities_on_cycle_id"
    t.index ["developer_id"], name: "index_cycle_operational_activities_on_developer_id"
  end

  create_table "cycles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.string "name", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_cycles_on_end_date"
    t.index ["start_date"], name: "index_cycles_on_start_date"
  end

  create_table "deliverable_allocations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.float "allocated_hours", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.uuid "deliverable_id", null: false
    t.uuid "developer_id", null: false
    t.date "end_date", null: false
    t.float "operational_hours", default: 0.0, null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.index ["deliverable_id", "developer_id"], name: "idx_deliverable_allocations_dev_deliverable"
    t.index ["deliverable_id"], name: "index_deliverable_allocations_on_deliverable_id"
    t.index ["developer_id"], name: "index_deliverable_allocations_on_developer_id"
  end

  create_table "deliverables", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "cycle_id"
    t.string "deliverable_type", default: "bet", null: false
    t.string "jira_link"
    t.integer "priority", default: 0
    t.string "specific_stack", null: false
    t.string "status", default: "backlog", null: false
    t.uuid "team_id", null: false
    t.string "title", null: false
    t.float "total_effort_hours", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.index ["cycle_id"], name: "index_deliverables_on_cycle_id"
    t.index ["priority"], name: "index_deliverables_on_priority"
    t.index ["specific_stack"], name: "index_deliverables_on_specific_stack"
    t.index ["status"], name: "index_deliverables_on_status"
    t.index ["team_id"], name: "index_deliverables_on_team_id"
  end

  create_table "developer_cycle_capacities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "cycle_id", null: false
    t.uuid "developer_id", null: false
    t.float "gross_hours", default: 0.0, null: false
    t.float "real_capacity", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.index ["cycle_id", "developer_id"], name: "idx_dev_cycle_capacities_unique", unique: true
    t.index ["cycle_id"], name: "index_developer_cycle_capacities_on_cycle_id"
    t.index ["developer_id"], name: "index_developer_cycle_capacities_on_developer_id"
  end

  create_table "developers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "domain_stack", null: false
    t.string "name", null: false
    t.decimal "productivity_factor", precision: 4, scale: 2, default: "1.0", null: false
    t.string "seniority", null: false
    t.uuid "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_stack"], name: "index_developers_on_domain_stack"
    t.index ["seniority"], name: "index_developers_on_seniority"
    t.index ["team_id"], name: "index_developers_on_team_id"
  end

  create_table "holidays", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "name", null: false
    t.string "scope", default: "national", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_holidays_on_date", unique: true
  end

  create_table "jira_bugs", force: :cascade do |t|
    t.string "assignee"
    t.string "categories", default: [], array: true
    t.jsonb "comments"
    t.integer "comments_count"
    t.string "components", default: [], array: true
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "development_info"
    t.string "development_type"
    t.string "issue_key", null: false
    t.string "issue_type"
    t.datetime "jira_updated_at"
    t.string "labels", default: [], array: true
    t.datetime "opened_at", null: false
    t.string "priority"
    t.string "reporter"
    t.text "root_cause_analysis"
    t.string "status"
    t.string "team"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_key"], name: "index_jira_bugs_on_issue_key", unique: true
    t.index ["issue_type"], name: "index_jira_bugs_on_issue_type"
    t.index ["jira_updated_at"], name: "index_jira_bugs_on_jira_updated_at"
    t.index ["opened_at"], name: "index_jira_bugs_on_opened_at"
    t.index ["priority"], name: "index_jira_bugs_on_priority"
    t.index ["status"], name: "index_jira_bugs_on_status"
    t.index ["team"], name: "index_jira_bugs_on_team"
    t.check_constraint "development_type IS NULL OR (development_type::text = ANY (ARRAY['Backend'::character varying::text, 'Frontend'::character varying::text]))", name: "chk_jira_bugs_development_type"
  end

  create_table "pull_requests", force: :cascade do |t|
    t.integer "additions"
    t.string "author_login"
    t.string "author_name"
    t.integer "changed_files"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.integer "deletions"
    t.bigint "github_id", null: false
    t.datetime "merged_at"
    t.string "normalized_author_name"
    t.integer "number", null: false
    t.datetime "opened_at"
    t.bigint "repository_id", null: false
    t.string "state", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_pull_requests_on_github_id", unique: true
    t.index ["normalized_author_name"], name: "index_pull_requests_on_normalized_author_name"
    t.index ["opened_at"], name: "index_pull_requests_on_opened_at"
    t.index ["repository_id", "number"], name: "index_pull_requests_on_repository_id_and_number", unique: true
    t.index ["repository_id"], name: "index_pull_requests_on_repository_id"
    t.index ["state"], name: "index_pull_requests_on_state"
  end

  create_table "repositories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "github_id"
    t.string "language"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_repositories_on_github_id", unique: true
    t.index ["name"], name: "index_repositories_on_name", unique: true
  end

  create_table "sync_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "key", null: false
    t.text "last_error"
    t.datetime "last_synced_at"
    t.string "status", default: "idle", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_sync_settings_on_key", unique: true
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  add_foreign_key "absences", "developers"
  add_foreign_key "commits", "repositories"
  add_foreign_key "cycle_operational_activities", "cycles"
  add_foreign_key "cycle_operational_activities", "developers"
  add_foreign_key "deliverable_allocations", "deliverables"
  add_foreign_key "deliverable_allocations", "developers"
  add_foreign_key "deliverables", "cycles"
  add_foreign_key "deliverables", "teams"
  add_foreign_key "developer_cycle_capacities", "cycles"
  add_foreign_key "developer_cycle_capacities", "developers"
  add_foreign_key "developers", "teams"
  add_foreign_key "pull_requests", "repositories"
end
