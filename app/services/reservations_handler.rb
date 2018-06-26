class ReservationsHandler
  def initialize(user, book)
    @user = user
    @book = book
  end

  def reserve
    return "Book is not available for reservation" unless book.can_be_reserved?(user)
    book.reservations.create(user: user, status: 'RESERVED')
  end

  def cancel_reservation
    book.reservations.where(user: user, status: 'RESERVED').order(created_at: :asc).first.update_attributes(status: 'CANCELED')
  end

  def take
    return "Book cannot be taken" unless book.can_take?(user)

    if book.available_reservation.present?
      perform_expiration_worker(book.available_reservation)
      book.available_reservation.update_attributes(status: 'TAKEN')
    else
      reservation = book.reservations.create(user: user, status: 'TAKEN')
      perform_expiration_worker(reservation)
    end
    ReservationMailer.reservation_confirmation(user, book).deliver_now
  end

  def give_back
    ActiveRecord::Base.transaction do
      book.reservations.find_by(status: 'TAKEN').update_attributes(status: 'RETURNED')
      book.next_in_queue.update_attributes(status: 'AVAILABLE') if book.next_in_queue.present?
    end
  end

  private
  attr_reader :book, :user

  def perform_expiration_worker(res)
    ::BookReservationExpireWorker.perform_at(res.expires_at-1.day, res.book_id)
  end
end
