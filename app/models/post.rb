class Post < ApplicationRecord
  belongs_to :user
  belongs_to :group, optional: true

  has_many_attached :images
  validates :group, presence: true
end
