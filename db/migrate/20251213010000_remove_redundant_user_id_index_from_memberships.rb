class RemoveRedundantUserIdIndexFromMemberships < ActiveRecord::Migration[8.0]
  def change
    remove_index :memberships, :user_id
  end
end
