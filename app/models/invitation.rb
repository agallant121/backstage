class Invitation < ApplicationRecord
  belongs_to :group
  belongs_to :inviter, class_name: "User"
  belongs_to :invited_user, class_name: "User", optional: true

  before_validation :normalize_email
  before_validation :generate_token, on: :create

  scope :pending, -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  validates :email, presence: true
  validates :token, presence: true, uniqueness: true

  def pending?
    accepted_at.nil?
  end

  def accepted?
    !accepted_at.nil?
  end

  def accept!(user)
    transaction do
      begin
        Membership.find_or_create_by!(group: group, user: user)
      rescue ActiveRecord::RecordNotUnique
        Membership.find_by!(group: group, user: user)
      end

      update!(accepted_at: Time.current, invited_user: user)
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(12)
  end

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
