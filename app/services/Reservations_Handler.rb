class ReservationsHandler
   def initialize(user, book)
    @user = user
    @book = book
  end

  def reserve
    return "Book is not available for reservation" unless book.can_reserve?(user)
    reservations.create(user: user, status: 'RESERVED')
  end

  def cancel_reservation
    reservations.where(user: user, status: 'RESERVED').order(created_at: :asc).first.update_attributes(status: 'CANCELED')
  end

  def give_back
    ActiveRecord::Base.transaction do
      reservations.find_by(status: 'TAKEN').update_attributes(status: 'RETURNED')
      next_in_queue.update_attributes(status: 'AVAILABLE') if next_in_queue.present?
    end
  end

  def take
    return "Book can not be taken at the moment" unless book.can_take?(user)
    if book.available_reservation.present?
      book.available_reservation.update_attributes(status: 'TAKEN')
    else
      reservations.create(user: user, status: 'TAKEN')
    end
  end

  private
  delegate :reservations, to: :book
  attr_reader :user, :book

  def next_in_queue
    reservations.where(status: 'RESERVED').order(created_at: :asc).first
  end


end
