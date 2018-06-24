class BooksNotifierMailer < ApplicationMailer
  default from: 'warsztaty@infakt.pl'
  layout 'mailer'

  def send_if_taken(book, user)
    @book = book
    @user = user

    mail(to: user.email, subject: "Book taken")
  end

  def send_if_reserved(book, user)
    @book = book
    @user = user

    mail(to: user.email, subject: "Book reserved")
  end

  def send_taken_before_due(book)
    @book = book
    @reservation = book.reservations.find_by(status: "TAKEN")
    @borrower = @reservation.user

    mail(to: @borrower.email, subject: "Book #{@book.title} give back is due")
  end

  def send_reserved(book)
    @book = book
    @reservation = book.reservations.find_by(status: "RESERVED")
    return unless @reservation
    @borrower = @reservation.user

    mail(to: @borrower.email, subject: "Book #{@book.title} reserved is almost there")
  end



end
