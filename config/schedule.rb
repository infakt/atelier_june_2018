every 1.day, at: '8:00 am' do
  rake 'reservation:send_notification', environment: 'development'
end

every 1.month do
  rake 'reservation:cancel_overreserved', environment: 'development'
end
