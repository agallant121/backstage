class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :posts, dependent: :destroy
  has_many :children, dependent: :destroy, inverse_of: :user

  accepts_nested_attributes_for :children, allow_destroy: true, reject_if: :all_blank

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def display_name
    full_name.presence || email
  end
end
