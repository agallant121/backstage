require "rails_helper"

RSpec.describe User do
  describe "#full_name" do
    it "joins first and last name" do
      user = described_class.new(first_name: "Jess", last_name: "Ortiz")

      expect(user.full_name).to eq("Jess Ortiz")
    end

    it "handles missing name parts" do
      user = described_class.new(first_name: "Jess")

      expect(user.full_name).to eq("Jess")
    end
  end

  describe "#display_name" do
    it "uses the full name when present" do
      user = described_class.new(first_name: "Jess", last_name: "Ortiz", email: "jess@example.com")

      expect(user.display_name).to eq("Jess Ortiz")
    end

    it "falls back to the email when the name is blank" do
      user = described_class.new(email: "jess@example.com")

      expect(user.display_name).to eq("jess@example.com")
    end
  end
end
