class AddIndexesForPostListQueries < ActiveRecord::Migration[8.0]
  def change
    remove_index :post_groups, :group_id

    add_index :post_groups, [ :group_id, :post_id ]
    add_index :posts, :created_at
  end
end
