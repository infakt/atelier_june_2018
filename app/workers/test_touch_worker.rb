class TestTouchWorker
  include Sidekiq::Worker

  def perform(book_id)
    Book.find(book_id).touch
  end
end
