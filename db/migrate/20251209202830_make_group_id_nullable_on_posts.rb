class MakeGroupIdNullableOnPosts < ActiveRecord::Migration[7.1]
  def change
    change_column_null :posts, :group_id, true
  end
end
