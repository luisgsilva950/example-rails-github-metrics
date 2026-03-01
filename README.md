# Rails GitHub Metrics

Engineering metrics dashboard built with Rails 8.1. Aggregates data from GitHub (commits, pull requests) and Jira (bugs), and includes a capacity planning module for development cycles.

[![CI](https://github.com/Luisgsilva950/example-rails-github-metrics/actions/workflows/ci.yml/badge.svg)](https://github.com/Luisgsilva950/example-rails-github-metrics/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Luisgsilva950/example-rails-github-metrics/graph/badge.svg)](https://codecov.io/gh/Luisgsilva950/example-rails-github-metrics)

---

## Features

### Metrics Dashboard

- **Author Ranking** — commits by author with per-repository breakdown
- **Jira Bugs** — categorization, bubble charts, trends over time, unclassified/invalid bug tracking
- **Sync Controls** — toggle Jira sync from the dashboard UI

### Capacity Planning

- **Teams & Developers** — manage teams, developers (stack, seniority, productivity factor), and absences
- **Cycles** — define time-boxed delivery cycles with holiday-aware work day calculation
- **Deliverables** — track bets, spillovers, and technical debt with effort estimation
- **Allocations** — assign developers to deliverables with a Gantt-style plan view

### Data Extraction

- **GitHub** — extracts repositories, commits, and pull requests via Octokit
- **Jira** — imports bugs with categories, components, RCA, and priority via JQL

---

## Tech Stack

| Layer           | Technology                 |
| --------------- | -------------------------- |
| Framework       | Rails 8.1, Ruby 3.2        |
| Database        | PostgreSQL 15              |
| Background Jobs | Solid Queue                |
| Asset Pipeline  | Propshaft + Import Maps    |
| Frontend        | Hotwire (Turbo + Stimulus) |
| Tests           | RSpec, FactoryBot          |
| Coverage        | SimpleCov + Codecov        |
| Linting         | RuboCop                    |
| Security        | Brakeman, bundler-audit    |
| CI/CD           | GitHub Actions             |

---

## Getting Started

### Prerequisites

- Ruby 3.2.3
- PostgreSQL 15+
- Node.js (for import maps audit)

### Setup

```bash
# Clone the repository
git clone https://github.com/Luisgsilva950/example-rails-github-metrics.git
cd example-rails-github-metrics

# Start PostgreSQL (via Docker)
docker compose up -d db

# Install dependencies and prepare the database
bundle install
bin/rails db:create db:migrate db:seed

# Start the server
bin/rails server
```

The app will be available at `http://localhost:3000`.

---

## Environment Variables

### GitHub Integration

| Variable                    | Description                           | Default |
| --------------------------- | ------------------------------------- | ------- |
| `GITHUB_ACCESS_TOKEN`       | Personal access token with repo scope | —       |
| `GITHUB_API_RETRY_MAX`      | Max retry attempts                    | `3`     |
| `GITHUB_API_RETRY_INTERVAL` | Seconds between retries               | `1`     |
| `GITHUB_API_RETRY_BACKOFF`  | Backoff factor                        | `2`     |
| `GITHUB_OPEN_TIMEOUT`       | Connection timeout (seconds)          | `10`    |
| `GITHUB_READ_TIMEOUT`       | Read timeout (seconds)                | `30`    |
| `COMMITS_BATCH_SIZE`        | Batch size for commit processing      | `100`   |

### Jira Integration

| Variable             | Description                                                                              | Default |
| -------------------- | ---------------------------------------------------------------------------------------- | ------- |
| `JIRA_SITE`          | Jira instance URL (e.g. `https://company.atlassian.net`)                                 | —       |
| `JIRA_USERNAME`      | Jira account email                                                                       | —       |
| `JIRA_API_TOKEN`     | API token ([generate here](https://id.atlassian.com/manage-profile/security/api-tokens)) | —       |
| `JIRA_BUGS_JQL`      | JQL query to fetch bugs                                                                  | —       |
| `JIRA_MAX_RESULTS`   | Max issues per query                                                                     | `500`   |
| `JIRA_FIELDS`        | Comma-separated field list                                                               | `*all`  |
| `JIRA_EXPAND`        | Fields to expand (e.g. `changelog`)                                                      | —       |
| `JIRA_FETCH_FULL`    | Re-fetch individual issues                                                               | `true`  |
| `JIRA_SSL_CERT_FILE` | Custom SSL cert path                                                                     | —       |
| `JIRA_SSL_CERT_PATH` | Custom SSL cert directory                                                                | —       |
| `JIRA_VERIFY_SSL`    | Set to `0` to disable SSL verification (dev only)                                        | `1`     |

Create a `.env` file at the project root (it's gitignored):

```env
GITHUB_ACCESS_TOKEN=ghp_your_token_here
JIRA_SITE=https://your-instance.atlassian.net
JIRA_USERNAME=your.email@domain.com
JIRA_API_TOKEN=your_jira_token
JIRA_BUGS_JQL=project = ABC AND issuetype = Bug ORDER BY created DESC
```

---

## Data Extraction

### GitHub Metrics

```bash
bin/rake metrics:extract
```

### Jira Bugs

```bash
bin/rake jira:extract_bugs
```

If your Jira instance uses custom fields for categories or RCA, adjust `extract_categories` and `extract_rca` in `app/services/jira_bugs_extractor.rb`.

---

## API Endpoints

### Metrics

| Method | Path                                    | Description                      |
| ------ | --------------------------------------- | -------------------------------- |
| `GET`  | `/metrics/dashboard`                    | Main dashboard                   |
| `GET`  | `/metrics/authors`                      | Author ranking by commits (JSON) |
| `GET`  | `/metrics/jira_bugs/by_category`        | Bugs grouped by category (JSON)  |
| `GET`  | `/metrics/jira_bugs/unclassified`       | Unclassified bugs (JSON)         |
| `GET`  | `/metrics/jira_bugs/invalid_categories` | Invalid categories (JSON)        |
| `GET`  | `/metrics/jira_bugs/bubble_chart`       | Bubble chart data (JSON)         |
| `GET`  | `/metrics/jira_bugs/all`                | All bugs page                    |
| `GET`  | `/metrics/jira_bugs/bugs_over_time`     | Bugs over time chart             |
| `POST` | `/metrics/jira_bugs/sync_from_jira`     | Trigger Jira sync                |

### Planning

| Method | Path                        | Description             |
| ------ | --------------------------- | ----------------------- |
| `GET`  | `/planning/teams`           | List teams              |
| `GET`  | `/planning/developers`      | List developers         |
| `GET`  | `/planning/cycles`          | List cycles             |
| `GET`  | `/planning/cycles/:id/plan` | Cycle plan (Gantt view) |
| `GET`  | `/planning/deliverables`    | List deliverables       |

### Example

```bash
curl http://localhost:3000/metrics/authors | jq
```

```json
[
  {
    "author": "alice",
    "total_commits": 42,
    "repos": [
      { "name": "org/repo1", "commits": 10 },
      { "name": "org/repo2", "commits": 32 }
    ]
  }
]
```

---

## Tests

This project uses **RSpec** with **FactoryBot** and **SimpleCov** for coverage.

```bash
# Run the full test suite
bundle exec rspec

# Run a specific file
bundle exec rspec spec/services/normalize_author_name_spec.rb

# Run a specific test by line number
bundle exec rspec spec/services/normalize_author_name_spec.rb:5
```

Coverage reports are generated in `coverage/index.html` after each run.

---

## CI/CD

GitHub Actions runs 4 parallel jobs on every push to `main` and on pull requests:

| Job           | What it does                                                   |
| ------------- | -------------------------------------------------------------- |
| **scan_ruby** | Brakeman (static security analysis) + bundler-audit (CVE scan) |
| **scan_js**   | Import map JavaScript dependency audit                         |
| **lint**      | RuboCop with caching                                           |
| **test**      | RSpec + SimpleCov → Codecov upload + HTML coverage artifact    |

---

## Code Quality

This project follows the guidelines defined in [CLAUDE.md](CLAUDE.md):

- **Sandi Metz** — small classes (≤100 lines), small methods (≤5 lines), max 4 params
- **Avdi Grimm** — confident code, guard clauses, no silent nil returns
- **DHH** — convention over configuration, use Rails as designed
- **SOLID** — strict SRP and DIP with dependency injection throughout

---

## License

This project is for educational and personal use.
