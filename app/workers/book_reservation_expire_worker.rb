class BookReservationExpireWorker
  include Sidekiq::Worker

  def perform(book_id)
    book = Book.find(book_id)
    BooksNotifierMailer.send_taken_before_due(book).deliver
    BooksNotifierMailer.send_reserved(book).deliver
  end
end
