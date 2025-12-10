class Post < ApplicationRecord
  belongs_to :user
  belongs_to :group, optional: true

  has_many :post_groups, dependent: :destroy
  has_many :groups, through: :post_groups

  has_many_attached :images

  validates :body, presence: true
end
