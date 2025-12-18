class AddDefaultRoleToMemberships < ActiveRecord::Migration[8.0]
  def change
    change_column_default :memberships, :role, from: nil, to: 0

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE memberships
          SET role = 0
          WHERE role IS NULL
        SQL
      end
    end
  end
end
