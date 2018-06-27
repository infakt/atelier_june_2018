class AddCalendarEventOidToReservations < ActiveRecord::Migration[5.1]
  def change
     add_column :book_reservations, :calendar_event_oid, :string
  end
end
