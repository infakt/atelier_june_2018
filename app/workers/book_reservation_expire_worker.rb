class BookReservationExpireWorker
  include Sidekiq::Worker

  def perform(book_id)
    book = Book.find(book_id)
    ::ReservationsMailer.book_return_remind(book).deliver
    ::ReservationsMailer.book_reserved_return(book).deliver
  end
end
