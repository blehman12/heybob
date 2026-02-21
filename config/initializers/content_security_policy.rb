# Content Security Policy
# Protects against XSS by controlling which resources the browser can load.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "blob:"
    policy.object_src  :none
    # Allow scripts from self plus inline (needed for importmap/turbo)
    policy.script_src  :self, :unsafe_inline, :https
    # Allow styles from self plus inline (Bootstrap uses inline styles)
    policy.style_src   :self, :unsafe_inline, :https
    # Allow AJAX/fetch to our own origin only
    policy.connect_src :self
    # Prevent framing (clickjacking protection)
    policy.frame_ancestors :none
  end

  # Generate session nonces for permitted importmap and inline scripts
  # Uncomment when you're ready to tighten to remove :unsafe_inline above:
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w(script-src)
end
