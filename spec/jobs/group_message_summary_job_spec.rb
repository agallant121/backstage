require "rails_helper"

RSpec.describe GroupMessageSummaryJob, type: :job do
  it "refreshes the group's cached summary" do
    group = Group.create!(name: "Crew")
    generator = instance_double(Groups::MessageSummaryGenerator, call: true)

    expect(Groups::MessageSummaryGenerator).to receive(:new).with(group: group).and_return(generator)

    described_class.perform_now(group.id)
  end
end
