class ReservationsController < ApplicationController
  def reserve
    reservations_handler.reserve
    redirect_to(book_path(book.id))
    ReservationsMailer.notify_about_reservation(current_user, book).deliver_now
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

  private

  def reservations_handler
    @reservations_handler ||= ReservationsHandler.new(current_user, book)
  end

  def book
    @book ||= Book.find(params[:book_id])
  end
end
