class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def create
    cart = session[:cart] || {}
    @ebooks = Ebook.where(id: cart.keys)

    if @ebooks.empty?
      redirect_to cart_path, alert: "Your cart is empty."
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
    session[:cart] = {}

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
