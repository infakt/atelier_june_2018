require 'rails_helper'

describe 'AppRouting' do
  it {
    expect(root: 'books', action: 'index')
  }

  it {
    expect(get: "books/8/reserve").to route_to(
      controller: 'reservations',
      action: 'reserve',
      book_id: '8'
    )
  }

  it {
    expect(get: reserve_book_path(book_id: 8)).to route_to(
      controller: 'reservations',
      action: 'reserve',
      book_id: '8'
    )
  }

  it{
    expect(get: "books/8/take").to route_to(
      controller: 'reservations',
      action: 'take',
      book_id: '8'
    )
  }

  it{
    expect(get: "books/8/give_back").to route_to(
      controller: 'reservations',
      action: 'give_back',
      book_id: '8'
    )
  }

  it{
    expect(get: "books/8/cancel_reservation").to route_to(
      controller: 'reservations',
      action: 'cancel',
      book_id: '8'
    )
  }

  it{
    expect(get: "users/4/reservations").to route_to(
      controller: 'reservations',
      action: 'users_reservations',
      user_id: '4'
    )
  }

  it{
    expect(get: 'google-isbn').to route_to(
      controller: 'google_books',
      action: 'show'
    )
  }

  it{
    expect(get: 'books/new').to route_to(
      controller: 'books',
      action: 'new'
    )
  }

  it{
    expect(get: 'books').to route_to(
      controller: 'books',
      action: 'index'
    )
  }


  it{
    expect(post: 'books/new').to route_to(
      controller: 'books',
      action: 'new'
    )
  }
end
