class PostGroup < ApplicationRecord
  belongs_to :post
  belongs_to :group

  validates :post_id, uniqueness: { scope: :group_id }

  after_commit :refresh_group_summary, on: [ :create, :destroy ]

  private

  def refresh_group_summary
    group.refresh_message_summary_later
  end
end
