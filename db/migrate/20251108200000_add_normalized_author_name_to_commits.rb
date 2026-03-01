class AddNormalizedAuthorNameToCommits < ActiveRecord::Migration[8.1]
  def up
    add_column :commits, :normalized_author_name, :string
    add_index :commits, :normalized_author_name

    # Backfill
    say_with_time 'Backfilling normalized_author_name' do
      normalizer = AuthorNameNormalizer.new
      batch_size = 1000
      Commit.find_in_batches(batch_size: batch_size) do |batch|
        updates = []
        batch.each do |commit|
          original = commit.author_name
          next if original.nil?
          normalized = normalizer.call(original.to_s.downcase.strip) || original.strip
          updates << [commit.id, normalized]
        end
        # Atualiza em lote para reduzir N+1
        updates.each do |id, norm|
          Commit.where(id: id).update_all(normalized_author_name: norm)
        end
      end
    end
  end

  def down
    remove_index :commits, :normalized_author_name
    remove_column :commits, :normalized_author_name
  end
end
