class RemoveGroupIdFromPosts < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :group_id, :integer
  end
end
