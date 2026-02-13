class AddUniqueIndexToMembershipsOnUserAndGroup < ActiveRecord::Migration[8.0]
  def change
    add_index :memberships, %i[user_id group_id], unique: true
  end
end
