class AddExpirationToInvitations < ActiveRecord::Migration[8.0]
  def up
    add_column :invitations, :expires_at, :datetime

    execute <<~SQL.squish
      UPDATE invitations
      SET expires_at = created_at + interval '14 days'
      WHERE expires_at IS NULL
    SQL

    change_column_null :invitations, :expires_at, false
    add_index :invitations, :expires_at
  end

  def down
    remove_index :invitations, :expires_at
    remove_column :invitations, :expires_at
  end
end
