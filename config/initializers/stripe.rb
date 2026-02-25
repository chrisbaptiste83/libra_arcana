creds = Rails.application.credentials
stripe_config = creds.respond_to?(:[]) ? (creds[:stripe] || creds["stripe"]) : nil

credential_key =
  if stripe_config.is_a?(String)
    stripe_config
  elsif stripe_config.respond_to?(:[])
    stripe_config[:secret_key] || stripe_config["secret_key"]
  elsif creds.respond_to?(:[])
    creds[:stripe_secret_key] || creds["stripe_secret_key"]
  end

stripe_key = ENV["STRIPE_SECRET_KEY"].presence || credential_key
Stripe.api_key = stripe_key if stripe_key.present?
