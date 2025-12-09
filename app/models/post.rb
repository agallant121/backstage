class Post < ApplicationRecord
  belongs_to :user
  belongs_to :group  # keep this for now so old code still works

  has_many :post_groups, dependent: :destroy
  has_many :groups, through: :post_groups

  has_many_attached :images
end
