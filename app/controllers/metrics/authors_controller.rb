class Metrics::AuthorsController < ApplicationController
  def index
    page, size = pagination_params
    total_authors = total_distinct_authors
    total_pages = (total_authors.to_f / size).ceil

    authors_page = paginated_authors(page, size)
    repos_breakdown = repos_for_authors(authors_page.map(&:author))

    content = build_author_entries(authors_page, repos_breakdown)

    render json: {
      content: content,
      meta: {
        page: page,
        size: size,
        total_authors: total_authors,
        total_pages: total_pages
      }
    }
  end

  private

  def total_distinct_authors
    Commit.where.not(normalized_author_name: [nil, '']).distinct.count(:normalized_author_name)
  end

  def paginated_authors(page, size)
    offset = (page - 1) * size
    Commit.where.not(normalized_author_name: [nil, ''])
          .group(:normalized_author_name)
          .select("commits.normalized_author_name AS author", "COUNT(*) AS total_commits")
          .order("total_commits DESC")
          .limit(size)
          .offset(offset)
  end

  # Busca breakdown de repositórios apenas para os autores paginados
  def repos_for_authors(authors)
    return [] if authors.empty?
    Commit.joins(:repository)
          .where(normalized_author_name: authors)
          .group("commits.normalized_author_name", "repositories.name")
          .select(
            "commits.normalized_author_name AS author",
            "repositories.name AS repo_name",
            "COUNT(*) AS commits_count"
          )
  end

  def build_author_entries(authors_page, repo_rows)
    # Index repos por autor
    repos_by_author = Hash.new { |h, k| h[k] = [] }
    repo_rows.each do |r|
      repos_by_author[r.author] << { name: r.repo_name, commits: r.commits_count.to_i }
    end
    authors_page.map do |a|
      repos = repos_by_author[a.author]
      {
        author: a.author,
        total_commits: a.total_commits.to_i,
        total_repos: repos.size,
        repos: repos.sort_by { |e| -e[:commits] }
      }
    end
  end

  def pagination_params
    page = params.fetch(:page, 1).to_i
    size = params.fetch(:size, 25).to_i
    page = 1 if page < 1
    size = 25 if size <= 0
    size = 10000 if size > 10000
    [page, size]
  end
end
