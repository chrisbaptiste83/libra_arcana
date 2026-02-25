class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def create
    cart = session[:cart] || {}
    @ebooks = Ebook.where(id: cart.keys)

    if @ebooks.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    if Stripe.api_key.blank?
      redirect_to cart_path, alert: "Checkout is not configured yet. Please contact support."
      return
    end

    line_items = @ebooks.map do |ebook|
      {
        price_data: {
          currency: "usd",
          product_data: { name: ebook.title },
          unit_amount: (ebook.price * 100).to_i
        },
        quantity: 1
      }
    end

    ebook_ids = @ebooks.map(&:id).join(",")

    begin
      checkout_session = Stripe::Checkout::Session.create(
        payment_method_types: ["card"],
        line_items: line_items,
        mode: "payment",
        success_url: checkout_success_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: checkout_cancel_url,
        metadata: {
          user_id: current_user.id,
          ebook_ids: ebook_ids
        }
      )
    rescue Stripe::StripeError => e
      Rails.logger.error("Stripe checkout session creation failed: #{e.class} - #{e.message}")
      redirect_to cart_path, alert: "Unable to start checkout right now. Please try again."
      return
    end

    session[:cart] = {}
    redirect_to checkout_session.url, allow_other_host: true
  end

  def success
    @session_id = params[:session_id]
    if @session_id && current_user
      @download_accesses = current_user.download_accesses.active.includes(:ebook).order(created_at: :desc).limit(10)
    end
  end

  def cancel
  end
end
