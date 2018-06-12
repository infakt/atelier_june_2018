require 'rails_helper'

describe 'AppRouting', type: :routing do
  it {
    expect(root: 'books', action: 'index')
  }

  it {
    expect(get: 'books/12/reserve').to route_to(
      controller: 'reservations',
      action: 'reserve',
      book_id: '12'
    )
  }

  it {
    expect(get: take_book_path(book_id: 12)).to route_to(
      controller: 'reservations',
      action: 'take',
      book_id: '12'
    )
  }

  it {
    expect(get: give_back_book_path(book_id: 12)).to route_to(
      controller: 'reservations',
      action: 'give_back',
      book_id: '12'
    )
  }

  it {
    expect(get: cancel_book_reservation_path(book_id: 12)).to route_to(
      controller: 'reservations',
      action: 'cancel',
      book_id: '12'
    )
  }

  it {
    expect(get: users_reservations_path(user_id: 42)).to route_to(
      controller: 'reservations',
      action: 'users_reservations',
      user_id: '42'
    )
  }

  it {
    expect(get: 'google-isbn').to route_to(
      controller: 'google_books',
      action: 'show'
    )
  }

  it {
    expect(get: books_path).to route_to(controller: 'books', action: 'index')
  }

  it {
    expect(post: books_path).to route_to(controller: 'books', action: 'create')
  }

  it {
    expect(get: new_book_path).to route_to(controller: 'books', action: 'new')
  }

  it {
    expect(get: edit_book_path(id: 11)).to route_to(controller: 'books', action: 'edit', id: '11')
  }

  it {
    expect(get: book_path(id: 11)).to route_to(controller: 'books', action: 'show', id: '11')
  }

  it {
    expect(patch: book_path(id: 11)).to route_to(controller: 'books', action: 'update', id: '11')
  }

  it {
    expect(put: book_path(id: 11)).to route_to(controller: 'books', action: 'update', id: '11')
  }

  it {
    expect(delete: book_path(id: 11)).to route_to(controller: 'books', action: 'destroy', id: '11')
  }
end
