class Post < ApplicationRecord
  belongs_to :user

  has_many :post_groups, dependent: :destroy
  has_many :groups, through: :post_groups

  has_many_attached :images

  validates :body, presence: true
end
