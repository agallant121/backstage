class AddMembershipsCountToGroups < ActiveRecord::Migration[8.0]
  def up
    add_column :groups, :memberships_count, :integer, null: false, default: 0

    execute <<~SQL.squish
      UPDATE groups
      SET memberships_count = membership_counts.count
      FROM (
        SELECT group_id, COUNT(*) AS count
        FROM memberships
        GROUP BY group_id
      ) AS membership_counts
      WHERE groups.id = membership_counts.group_id
    SQL
  end

  def down
    remove_column :groups, :memberships_count
  end
end
