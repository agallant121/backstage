class PostGroup < ApplicationRecord
  belongs_to :post
  belongs_to :group

  validates :post_id, uniqueness: { scope: :group_id }
end
