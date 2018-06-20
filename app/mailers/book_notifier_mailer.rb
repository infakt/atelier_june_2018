class BookNotifierMailer < ApplicationMailer
  def book_return_remind(book)
    @book = book
    @reservation = book.reservations.find_by(status: 'TAKEN')
    @user = @reservation.user

    mail(to: @user.email, subject: "Oddej mordo tą książke(#{@book.title})!!!!")
  end
end
