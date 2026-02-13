module Groups
  class InviteUsers
    Result = Struct.new(:notice, :alert, keyword_init: true)

    def self.call(group:, inviter:, raw_emails:, limits:)
      new(group: group, inviter: inviter, raw_emails: raw_emails, limits: limits).call
    end

    def initialize(group:, inviter:, raw_emails:, limits:)
      @group = group
      @inviter = inviter
      @raw_emails = raw_emails
      @limits = limits
    end

    def call
      emails = extract_emails(@raw_emails)
      error = validate_limits(emails)
      return Result.new(alert: error) if error

      outcome = Groups::InviteUsersProcessor.call(group: @group, inviter: @inviter, emails: emails)
      build_result(outcome)
    end

    private

    def extract_emails(raw)
      raw
        .to_s
        .split(/[\s,;]/)
        .map { |email| email.strip.downcase }
        .compact_blank
        .uniq
    end

    def validate_limits(emails)
      return "Please provide at least one email address." if emails.empty?

      return "Please limit invites to #{@limits[:per_request]} emails at a time." if emails.size > @limits[:per_request]

      if invites_week_count + emails.size > @limits[:per_week]
        return "You have reached the weekly invite limit (#{@limits[:per_week]}). Try again next week."
      end

      if invites_total_count + emails.size > @limits[:total]
        return "You have reached the total invite limit (#{@limits[:total]})."
      end

      nil
    end

    def build_result(outcome)
      notice = build_notice(outcome.created, outcome.reissued)
      alert = build_alert(outcome.skipped)

      Result.new(
        notice: notice.presence,
        alert: alert.presence
      )
    end

    def build_notice(created, reissued)
      [
        ("Invited #{created.join(', ')}" if created.any?),
        ("Reissued invites for #{reissued.join(', ')}" if reissued.any?)
      ].compact.join("\n")
    end

    def build_alert(skipped)
      skipped.join("\n")
    end

    def invites_week_count
      @inviter.sent_invitations.where(created_at: Time.zone.now.beginning_of_week..).count
    end

    def invites_total_count
      @inviter.sent_invitations.count
    end
  end

  class InviteUsersProcessor
    Outcome = Struct.new(:created, :reissued, :skipped, keyword_init: true)

    def self.call(group:, inviter:, emails:)
      new(group: group, inviter: inviter, emails: emails).call
    end

    def initialize(group:, inviter:, emails:)
      @group = group
      @inviter = inviter
      @emails = emails
    end

    def call
      created = []
      reissued = []
      skipped = []

      @emails.each do |email|
        result = process_one_email(email)

        case result[:status]
        when :created
          created << result[:email]
        when :reissued
          reissued << result[:email]
        when :skipped
          skipped << result[:message]
        end
      end

      Outcome.new(created: created, reissued: reissued, skipped: skipped)
    end

    private

    def process_one_email(email)
      return skip("#{email} because they are already in one of your groups.") if already_in_inviter_groups?(email)
      return handle_existing_pending(email) if pending_invite_exists?(email)
      return skip("#{email} because they are already a member.") if already_member?(email)

      create_invitation(email)
    end

    def handle_existing_pending(email)
      invitation = @group.invitations.pending.find_by(email: email)

      if invitation.expired?
        invitation.reissue!
        InvitationMailer.invite(invitation).deliver_later
        { status: :reissued, email: invitation.email }
      else
        skip("#{email} because they already have a pending invite.")
      end
    end

    def create_invitation(email)
      invitation = @group.invitations.build(email: email, inviter: @inviter)

      if invitation.save
        InvitationMailer.invite(invitation).deliver_later
        { status: :created, email: invitation.email }
      else
        skip("#{email}: #{invitation.errors.full_messages.to_sentence}.", prefix: "Could not invite ")
      end
    end

    def pending_invite_exists?(email)
      @group.invitations.pending.exists?(email: email)
    end

    def already_member?(email)
      @group.users.exists?(email: email)
    end

    def already_in_inviter_groups?(email)
      user = User.find_by(email: email)
      return false if user.nil?

      user.group_ids.intersect?(@inviter.group_ids)
    end

    def skip(message, prefix: "Skipped ")
      { status: :skipped, message: "#{prefix}#{message}" }
    end
  end
end
