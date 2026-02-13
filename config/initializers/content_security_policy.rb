# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.object_src :none
    policy.frame_ancestors :none

    policy.font_src :self, :https, :data
    policy.img_src :self, :https, :data
    policy.script_src :self, :https, "https://cdn.jsdelivr.net"
    policy.style_src :self, :https, "https://cdn.jsdelivr.net"
    policy.form_action :self

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Enforce policy in production traffic.
  config.content_security_policy_report_only = false
end
