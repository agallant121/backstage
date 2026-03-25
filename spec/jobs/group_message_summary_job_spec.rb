require "rails_helper"

RSpec.describe GroupMessageSummaryJob, type: :job do
  it "refreshes the group's cached summary" do
    group = Group.create!(name: "Crew")
    generator = instance_spy(Groups::MessageSummaryGenerator)

    allow(Groups::MessageSummaryGenerator).to receive(:new).with(group: group).and_return(generator)

    described_class.perform_now(group.id)

    expect(Groups::MessageSummaryGenerator).to have_received(:new).with(group: group)
    expect(generator).to have_received(:call)
  end
end
