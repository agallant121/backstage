require "rails_helper"

RSpec.describe "Memberships", type: :request do
  it "allows group admins to remove members" do
    admin = User.create!(email: "admin@example.com", password: "password")
    member = User.create!(email: "member@example.com", password: "password")
    group = Group.create!(name: "Group One")

    admin_membership = Membership.create!(user: admin, group: group, role: :admin)
    member_membership = Membership.create!(user: member, group: group, role: :member)

    sign_in admin

    expect do
      delete group_membership_path(group, member_membership)
    end.to change(Membership, :count).by(-1)

    expect(response).to redirect_to(group_path(group))
    expect(Membership.where(id: member_membership.id)).not_to exist
    expect(Membership.where(id: admin_membership.id)).to exist
  end

  it "prevents non-admins from removing members" do
    admin = User.create!(email: "admin@example.com", password: "password")
    member = User.create!(email: "member@example.com", password: "password")
    group = Group.create!(name: "Group Two")

    Membership.create!(user: admin, group: group, role: :admin)
    member_membership = Membership.create!(user: member, group: group, role: :member)

    sign_in member

    expect do
      delete group_membership_path(group, member_membership)
    end.not_to change(Membership, :count)

    expect(response).to redirect_to(group_path(group))
    expect(Membership.where(id: member_membership.id)).to exist
  end
end
