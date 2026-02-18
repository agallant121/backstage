Rails.application.config.session_store(
  :cache_store,
  key: "_backstage_session",
  expire_after: 14.days,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
)
