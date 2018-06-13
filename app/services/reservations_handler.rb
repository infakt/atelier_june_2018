class ReservationsHandler

  def initialize(book, user)
    @book = book
    @user = user
end


def reserve
  return "Book is not available for reservation " unless book.can_be_reserved?(user)
  book.reservations.create( user: user, status:"RESERVED")
end

def cancel_reservation
  book.reservations.where(user: user, status: 'RESERVED').order(created_at: :asc).first.update_attributes(status: 'CANCELED')
end

def take
  return unless book.can_take?(user)

  if book.available_reservation.present?
    book.available_reservation.update_attributes(status: 'TAKEN')
  else
    book.reservations.create(user: user, status: 'TAKEN')
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



end
