class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :group, counter_cache: true

  enum :role, { member: 0, admin: 1 }

  validates :user_id, uniqueness: { scope: :group_id }
end
