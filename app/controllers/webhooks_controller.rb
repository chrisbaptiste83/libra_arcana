class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = stripe_webhook_secret

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      return render json: { error: "Invalid payload or signature" }, status: 400
    end

    case event["type"]
    when "checkout.session.completed"
      handle_successful_payment(event["data"]["object"])
    end

    render json: { status: "success" }
  end

  private

  def stripe_webhook_secret
    creds = Rails.application.credentials
    stripe_config = creds.respond_to?(:[]) ? (creds[:stripe] || creds["stripe"]) : nil

    credential_secret =
      if stripe_config.is_a?(String)
        nil
      elsif stripe_config.respond_to?(:[])
        stripe_config[:webhook_secret] || stripe_config["webhook_secret"]
      elsif creds.respond_to?(:[])
        creds[:stripe_webhook_secret] || creds["stripe_webhook_secret"]
      end

    ENV["STRIPE_WEBHOOK_SECRET"].presence || credential_secret
  end

  def handle_successful_payment(session)
    user = User.find_by(id: session["metadata"]["user_id"])
    return unless user

    return if Order.exists?(stripe_session_id: session["id"])

    order = Order.create!(
      user: user,
      total: session["amount_total"] / 100.0,
      status: "completed",
      stripe_session_id: session["id"]
    )

    ebook_ids = session["metadata"]["ebook_ids"].split(",").map(&:to_i)
    ebooks = Ebook.where(id: ebook_ids)

    ebooks.each do |ebook|
      OrderItem.create!(
        order: order,
        ebook: ebook,
        unit_price: ebook.price
      )

      DownloadAccess.create!(
        user: user,
        ebook: ebook,
        order: order,
        expires_at: 30.days.from_now,
        download_count: 0
      )
    end

    Payment.create!(
      order: order,
      amount: order.total,
      stripe_payment_id: session["payment_intent"],
      status: "completed"
    )
  end
end
