class AddIndexesToCommits < ActiveRecord::Migration[8.1]
  def change
    # Index já existe em :sha (unique) e :normalized_author_name (migration anterior).
    # Adicionamos índices para melhorar consultas comuns:
    # 1. repository_id + committed_at: facilitar busca de commits recentes por repositório.
    # 2. committed_at sozinho: facilitar ordenações globais / filtros por data.
    add_index :commits, [:repository_id, :committed_at]
    add_index :commits, :committed_at
  end
end
