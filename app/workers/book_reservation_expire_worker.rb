class BookReservationExpireWorker
  include Sidekiq::Worker

  def perform(book_id)
    
  end
end
