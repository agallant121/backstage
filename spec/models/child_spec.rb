require "rails_helper"

RSpec.describe Child do
  include ActiveSupport::Testing::TimeHelpers

  describe "#age_display" do
    it "formats age from explicit age" do
      child = described_class.new(age: 3)

      expect(child.age_display).to eq("3 years")
    end

    it "formats age in months when younger than two years" do
      travel_to Date.new(2024, 7, 15) do
        child = described_class.new(birthday: Date.new(2023, 12, 20))

        expect(child.age_display).to eq("6 months")
      end
    end

    it "formats age in years for older children" do
      travel_to Date.new(2024, 7, 15) do
        child = described_class.new(birthday: Date.new(2020, 7, 14))

        expect(child.age_display).to eq("4 years")
      end
    end
  end
end
