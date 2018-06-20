class BookNotifierMailer < ApplicationMailer
  def book_return_remind(book)
    @book = book
    @reservation = book.reservations.find_by(status: "TAKEN")
    @user = @reservation.user

    mail(to: @user.email, subject: "Oddej mordo tą książke(#{@book.title})!!!!")
  end

  def book_reserved_return(book)
    @book = book
    @reservation = book.reservations.find_by(status: "RESERVED")
    @user = @reservation.user

    mail(to: @user.email, subject: "Niebawem książka #{@book.title} będzie dostępna!!")
  end
end
