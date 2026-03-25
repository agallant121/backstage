class GroupMessageSummaryJob < ApplicationJob
  queue_as :default

  def perform(group_id)
    group = Group.find_by(id: group_id)
    return unless group

    Groups::MessageSummaryGenerator.new(group: group).call
  end
end
