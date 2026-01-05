require "rails_helper"

RSpec.describe Membership do
  it "enforces uniqueness of user within a group" do
    user = User.create!(email: "member@example.com", password: "password")
    group = Group.create!(name: "Group")

    described_class.create!(user: user, group: group)
    duplicate = described_class.new(user: user, group: group)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("has already been taken")
  end
end
