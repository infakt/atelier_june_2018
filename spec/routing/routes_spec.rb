require 'rails_helper'

describe 'AppRouting' do
  it {
    expect(root: 'books', action: 'index')
  }

  it {
  expect(get: 'books/12/reserve').to route_to(controller: 'reservations', action: 'reserve', book_id: '12')
  }

  it {
    expect(get: reserve_book_path(book_id: 12)).to route_to(controller: 'reservations', action: 'reserve', book_id: '12')
  }

  it {
    expect(get: 'books/12/take').to route_to(controller: 'reservations', action: 'take', book_id: '12')
  }

  it {
    expect(get: 'books/12/take').to route_to(controller: 'reservations', action: 'give_back', book_id: '12')
  }
end
