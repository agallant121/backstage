class AddIndexesForPostListQueries < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :post_groups, [ :group_id, :post_id ], algorithm: :concurrently
    remove_index :post_groups, column: :group_id, algorithm: :concurrently
    add_index :posts, :created_at, algorithm: :concurrently
  end

  def down
    add_index :post_groups, :group_id, algorithm: :concurrently
    remove_index :post_groups, column: [ :group_id, :post_id ], algorithm: :concurrently
    remove_index :posts, column: :created_at, algorithm: :concurrently
  end
end
