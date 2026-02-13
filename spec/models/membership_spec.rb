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

  # rubocop:disable RSpec/ExampleLength
  it "enforces uniqueness of user/group at the database level" do
    user = User.create!(email: "race-member@example.com", password: "password")
    group = Group.create!(name: "Race Group")

    # rubocop:disable Rails/SkipsModelValidations
    expect do
      now = Time.current
      described_class.insert_all!([
                                    {
                                      user_id: user.id,
                                      group_id: group.id,
                                      role: described_class.roles[:member],
                                      created_at: now,
                                      updated_at: now
                                    },
                                    {
                                      user_id: user.id,
                                      group_id: group.id,
                                      role: described_class.roles[:member],
                                      created_at: now,
                                      updated_at: now
                                    }
                                  ])
    end.to raise_error(ActiveRecord::RecordNotUnique)
    # rubocop:enable Rails/SkipsModelValidations
  end
  # rubocop:enable RSpec/ExampleLength
end
