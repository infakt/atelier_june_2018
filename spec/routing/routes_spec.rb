require 'rails_helper'

describe 'AppRouting' do
  it {
    expect(root: 'books', action: 'index')
  }

  #get 'books/:book_id/reserve', to: 'reservations#reserve', as: 'reserve_book'

  it {
    expect(get: 'books/12/reserve').to route_to(controller: 'reservations', action: 'reserve', book_id: '12')
  }

  it {
    expect(get: reserve_book_path(book_id: 12)).to route_to(controller: 'reservations', action: 'reserve', book_id: '12')
  }

  #get 'books/:book_id/take', to: 'reservations#take', as: 'take_book'
  it {
    expect(get: 'books/12/take').to route_to(controller: 'reservations', action: 'take', book_id: '12')
  }

  #get 'books/:book_id/give_back', to: 'reservations#give_back', as: 'give_back_book'
  it {
    expect(get: 'books/12/give_back').to route_to(controller: 'reservations', action: 'give_back', book_id: '12')
  }

  #get 'books/:book_id/cancel_reservation', to: 'reservations#cancel', as: 'cancel_book_reservation'
  it {
    expect(get: 'books/12/cancel_reservation').to route_to(controller: 'reservations', action: 'cancel', book_id: '12')
  }

  #get 'users/:user_id/reservations', to: 'reservations#users_reservations', as: 'users_reservations'
  it {
    expect(get: 'users/12/reservations').to route_to(controller: 'reservations', action: 'users_reservations', user_id: '12')
  }

  #get 'google-isbn', to: 'google_books#show'
  it {
    expect(get: 'google-isbn').to route_to(controller: 'google_books', action: 'show')
  }

  #POST   /books(.:format)   books#create
  it {
    expect(post: 'books').to route_to(controller: 'books', action: 'create')
  }


end
