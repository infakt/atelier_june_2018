class BookNotifierMailer < ApplicationMailer
  def book_return_remind(book)
    @book = book
    @reservation = book.reservations.find_by(status: "TAKEN")
    @user = @reservation.try(:user)

    return if @user.blank?

    mail(to: @user.email, subject: "Oddej mordo tą książke(#{@book.title})!!!!")
  end

  def book_reserved_return(book)
    @book = book
    @reservation = book.reservations.find_by(status: "TAKEN")
    @reserver = book.reservations.where(status: "RESERVED").first.try(:user)

    return if @reservation.blank? || @reserver.blank?

    mail(to: @reserver.email, subject: "Niebawem książka #{@book.title} będzie dostępna!!")
  end
end
