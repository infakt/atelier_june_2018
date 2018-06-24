class ReservationsController < ApplicationController
  before_action :load_user, only: [:users_reservations]

  def reserve
    reservation_handler.reserve
    redirect_to(book_path(book.id))
    BooksNotifierMailer.send_if_reserved(book, current_user).deliver_now
  end

  def take
    reservation_handler.take
    redirect_to(book_path(book.id))
    BooksNotifierMailer.send_if_taken(book, current_user).deliver_now
  end

  def give_back
    reservation_handler.give_back if reservation_handler.can_give_back?
    redirect_to(book_path(book.id))
  end

  def cancel
    reservation_handler.cancel_reservation
    redirect_to(book_path(book.id))
  end

  def users_reservations
  end

  private

  def book
    @book ||= Book.find(params[:book_id])
  end

  def load_user
    @user = User.find(params[:user_id])
  end

  def reservation_handler
    @reservation_handler ||= ::ReservationsHandler.new(current_user, book)
  end
end
