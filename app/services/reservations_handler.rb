class ReservationsHandler
  def initialize(user, book)
    @user = user
    @book = book
  end

  def reserve
    return "Book is not available for reservation" unless can_be_reserved?
    book.reservations.create(user: user, status: 'RESERVED')
  end

  def cancel_reservation
    book.reservations.where(user: user, status: 'RESERVED').order(created_at: :asc).first.update_attributes(status: 'CANCELED')
  end

  def take
    return unless can_be_taken?

    if book.available_reservation.present?
      perform_expiration_worker(book.available_reservation)
      book.available_reservation.update_attributes(status: 'TAKEN')
    else
      perform_expiration_worker(book.reservations.create(user: user, status: 'TAKEN'))
    end
  end

  def give_back
    ActiveRecord::Base.transaction do
      book.reservations.find_by(status: 'TAKEN').update_attributes(status: 'RETURNED')
      next_in_queue.update_attributes(status: 'AVAILABLE') if next_in_queue.present?
    end
  end

  def next_in_queue
    book.reservations.where(status: 'RESERVED').order(created_at: :asc).first
  end

  def can_be_taken?
    not_taken? && ( book.available_for_user?(user) || book.reservations.empty? )
  end

  def can_give_back?
    book.reservations.find_by(user: user, status: 'TAKEN').present?
  end

  def can_be_reserved?
    book.reservations.find_by(user: user, status: 'RESERVED').nil?
  end

  def not_taken?
    book.reservations.find_by(status: 'TAKEN').nil?
  end

  private
  attr_reader :user, :book

  def perform_expiration_worker(res)
    ::BookReservationExpireWorker.perform_at(res.expires_at-1.day, res.book_id)
  end
end
