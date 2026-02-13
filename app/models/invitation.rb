class Invitation < ApplicationRecord
  TOKEN_TTL = 14.days

  belongs_to :group
  belongs_to :inviter, class_name: "User"
  belongs_to :invited_user, class_name: "User", optional: true

  before_validation :normalize_email
  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :pending, -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :expired, -> { pending.where(expires_at: ..Time.current) }

  validates :email, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def pending?
    accepted_at.nil?
  end

  def accepted?
    !accepted_at.nil?
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    pending? && !expired?
  end

  def accept!(user)
    raise ActiveRecord::RecordInvalid, self if !pending? || expired?

    transaction do
      begin
        Membership.find_or_create_by!(group: group, user: user)
      rescue ActiveRecord::RecordNotUnique
        Membership.find_by!(group: group, user: user)
      end

      update!(accepted_at: Time.current, invited_user: user)
    end
  end

  def reissue!
    update!(token: SecureRandom.hex(12), expires_at: TOKEN_TTL.from_now)
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(12)
  end

  def set_expiration
    self.expires_at ||= TOKEN_TTL.from_now
  end

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
