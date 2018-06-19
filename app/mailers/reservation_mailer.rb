class ReservationMailer < ApplicationMailer

  def reservation_confirmation(user, book)
    @user = user
    @book = book
    @reservation = user.reservations.where(book_id: book.id, status: "TAKEN").first

    mail(to: user.email, subject: "#{book.title} reservation confirmation")
  end
end
