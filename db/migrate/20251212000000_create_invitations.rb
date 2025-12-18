class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :group, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :invited_user, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
  end
end
