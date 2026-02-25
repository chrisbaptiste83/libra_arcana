creds = Rails.application.credentials

stripe_key =
  ENV["STRIPE_SECRET_KEY"] ||
  (creds.is_a?(String) ? creds : (creds.respond_to?(:dig) ? creds.dig(:stripe, :secret_key) : creds))

Stripe.api_key = stripe_key if stripe_key.present?
