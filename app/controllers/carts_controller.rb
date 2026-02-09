class CartsController < ApplicationController
  def show
    @cart = session[:cart] || {}
    @ebooks = Ebook.where(id: @cart.keys)
  end

  def add
    ebook = Ebook.find_by(id: params[:ebook_id])

    unless ebook
      redirect_to root_path, alert: "Ebook not found."
      return
    end

    session[:cart] ||= {}

    if session[:cart][ebook.id.to_s]
      redirect_back(fallback_location: ebooks_path, notice: "#{ebook.title} is already in your cart.")
      return
    end

    session[:cart][ebook.id.to_s] = 1
    redirect_back(fallback_location: ebooks_path, notice: "#{ebook.title} added to cart.")
  end

  def remove
    ebook = Ebook.find_by(id: params[:ebook_id])

    unless ebook
      redirect_to root_path, alert: "Ebook not found."
      return
    end

    session[:cart]&.delete(ebook.id.to_s)
    redirect_back(fallback_location: cart_path, notice: "#{ebook.title} removed from cart.")
  end

  def clear
    session[:cart] = {}
    redirect_to cart_path, notice: "Cart cleared."
  end
end
