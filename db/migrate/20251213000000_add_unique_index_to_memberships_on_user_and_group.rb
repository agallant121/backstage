class AddUniqueIndexToMembershipsOnUserAndGroup < ActiveRecord::Migration[8.0]

  def up
    deduplicate_memberships!
    add_index :memberships, %i[user_id group_id], unique: true
  end

  def down
    remove_index :memberships, %i[user_id group_id]
  end

  private

  def deduplicate_memberships!
    execute <<~SQL.squish
      DELETE FROM memberships AS duplicate
      USING memberships AS canonical
      WHERE duplicate.user_id = canonical.user_id
        AND duplicate.group_id = canonical.group_id
        AND duplicate.id > canonical.id
    SQL
  end
end
