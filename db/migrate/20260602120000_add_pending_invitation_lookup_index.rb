class AddPendingInvitationLookupIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :invitations, [ :group_id, :email, :accepted_at ], name: "index_invitations_on_group_email_accepted"
  end
end
