class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :posts, dependent: :destroy
  has_many :children, dependent: :destroy, inverse_of: :user
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :nullify
  has_many :received_invitations, class_name: "Invitation", foreign_key: :invited_user_id, dependent: :nullify

  accepts_nested_attributes_for :children, allow_destroy: true, reject_if: :all_blank

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def display_name
    full_name.presence || email
  end
end
