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

  def take(book)
    return "Book cannot be taken" unless book.can_take?(user)

    if book.available_reservation.present?
      book.available_reservation.update_attributes(status: 'TAKEN')
    else
      book.reservations.create(user: user, status: 'TAKEN')
    end
  end

  def give_back(book)
    ActiveRecord::Base.transaction do
      book.reservations.find_by(status: 'TAKEN').update_attributes(status: 'RETURNED')
      next_in_queue.update_attributes(status: 'AVAILABLE') if next_in_queue.present?
    end
  end

  def next_in_queue
    book.reservations.where(status: 'RESERVED').order(created_at: :asc).first
  end

  private
  attr_reader :book, :user
end