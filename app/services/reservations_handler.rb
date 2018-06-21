class ReservationsHandler
  def initialize(user, book)
    @user = user
    @book = book
  end

  def reserve
    return "Book is not available for reservation" unless book.can_reserve?(user)
    book.reservations.create(user: user, status: 'RESERVED')
  end

  def cancel_reservation
    book.reservations.where(user: user, status: 'RESERVED').order(created_at: :asc).first.update_attributes(status: 'CANCELED')
  end

  def take
    return "Book can not be taken at the moment" unless book.can_take?(user)
    if book.available_reservation.present?
      send_mailers(book.available_reservation)
      book.available_reservation.update_attributes(status: 'TAKEN')
    else
      send_mailers(book.reservations.create(user: user, status: 'TAKEN'))
    end
  end

  def give_back
    ActiveRecord::Base.transaction do
      book.reservations.find_by(status: 'TAKEN').update_attributes(status: 'RETURNED')
      book.next_in_queue.update_attributes(status: 'AVAILABLE') if book.next_in_queue.present?
    end
  end

  private
  attr_reader :user, :book

  def send_mailers(res)
    remind_date = res.expires_at - 1.day
    ::ReservationsMailer.delay(run_at: remind_date).book_return_remind(res.book)
    ::ReservationsMailer.delay(run_at: remind_date).book_reserved_return(res.book)
  end
end
