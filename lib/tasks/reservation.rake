namespace :reservation do
  desc "gather taken books that expire tomorrow"
  task gather_taken: :environment do
    reservations = Reservation.where(status: "TAKEN",expires_at: Date.tomorrow.all_day)
    reservations.each do |res|
      BookReservationExpireWorker.perform_at(Time.now, res.book.id)
    end
  end
end
