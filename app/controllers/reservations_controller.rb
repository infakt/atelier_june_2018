class ReservationsController < ApplicationController
  before_action :load_user, only: [:users_reservations]

  def reserve
    reservations_handler.reserve
    redirect_to(book_path(book.id))
  end

  def take
    reservations_handler.take
    redirect_to(book_path(book.id))
  end

  def give_back
    reservations_handler.give_back
    redirect_to(book_path(book.id))
  end

  def cancel
    reservations_handler.cancel_reservation
    redirect_to(book_path(book.id))
  end

  def users_reservations
  end

  private

  def reservations_handler
    @reservations_handler ||= ReservationsHandler.new(current_user, book)
  end

  def book
    @book ||= Book.find(params[:book_id])
  end

  def load_user
    @user = User.find(params[:user_id])
  end
end
