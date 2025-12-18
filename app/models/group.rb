class Group < ApplicationRecord
  has_many :memberships
  has_many :users, through: :memberships

  has_many :post_groups, dependent: :destroy
  has_many :posts, through: :post_groups
  has_many :invitations, dependent: :destroy
end
