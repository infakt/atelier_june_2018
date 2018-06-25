namespace :reservation do
  desc "Cancel too much reservation"
  task cancel_overreserved: :environment do
    users = User.joins(:reservations).group('user_id').having('count(user_id) > 20')
    users.each do |user|
      user.reservations.each { |res| res.update_attributes(status: 'CANCELED') }
    end
  end

  dec "send notification emails"
  task send_notification: :environment do
    reservations = Reservation.where(status: 'TAKEN').where('DATE(expires_at) = ?', Date.tomorrow)
    reservations.each do |res|
      BookNotifierMailer.book_reserved_return(res.book).deliver
    end
  end
end
