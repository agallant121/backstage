require "rails_helper"

RSpec.describe Invitation do
  let(:group) { Group.create!(name: "Families") }
  let(:inviter) { User.create!(email: "inviter@example.com", password: "password", confirmed_at: Time.current) }

  it "normalizes the email before validation" do
    invitation = described_class.new(group: group, inviter: inviter, email: "  Friend@Example.COM ")

    invitation.validate

    expect(invitation.email).to eq("friend@example.com")
  end

  it "generates a token on create" do
    invitation = described_class.create!(group: group, inviter: inviter, email: "friend@example.com")

    expect(invitation.token).to be_present
  end

  it "sets an expiration on create" do
    invitation = described_class.create!(group: group, inviter: inviter, email: "friend@example.com")

    expect(invitation.expires_at).to be_present
  end

  it "is pending when accepted_at is nil" do
    invitation = described_class.new(group: group, inviter: inviter, email: "friend@example.com")

    expect(invitation).to be_pending
  end

  it "accepts the invitation and creates membership" do
    invitation = described_class.create!(group: group, inviter: inviter, email: "friend@example.com")
    user = User.create!(email: "friend@example.com", password: "password", confirmed_at: Time.current)

    invitation.accept!(user)

    expect(invitation.reload.accepted_at).to be_present
    expect(invitation.invited_user).to eq(user)
    expect(Membership.exists?(group: group, user: user)).to be(true)
  end

  it "does not create a duplicate membership when one already exists" do
    invitation = described_class.create!(group: group, inviter: inviter, email: "friend@example.com")
    user = User.create!(email: "friend@example.com", password: "password", confirmed_at: Time.current)
    Membership.create!(group: group, user: user)

    expect { invitation.accept!(user) }.not_to change(Membership, :count)
    expect(invitation.reload.accepted_at).to be_present
  end

  it "does not accept an expired invitation" do
    invitation = described_class.create!(group: group, inviter: inviter, email: "friend@example.com",
                                         expires_at: 1.day.ago)
    user = User.create!(email: "friend@example.com", password: "password", confirmed_at: Time.current)

    expect { invitation.accept!(user) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(invitation.reload.accepted_at).to be_nil
  end

  it "reissues token and expiration" do
    invitation = described_class.create!(group: group, inviter: inviter, email: "friend@example.com",
                                         expires_at: 1.day.ago)
    old_token = invitation.token

    invitation.reissue!

    expect(invitation.token).not_to eq(old_token)
    expect(invitation.expires_at).to be > Time.current
  end
end
