require "rails_helper"

RSpec.describe ReservationsHandler, type: :service do
  let(:user) { User.new }
  subject { described_class.new(user) }

  describe '#reserve' do
    let(:book) { Book.new }

    before {
      allow(book).to receive_message_chain(:can_be_reserved?).with(user).and_return(can_be_reserved)
    }

    context 'without available book' do
      let(:can_be_reserved) { false }
      it {
        expect(subject.reserve(book)).to eq('Book is not available for reservation')
      }
    end

    context 'with available book ' do
      let(:can_be_reserved) { true }

      before {
        allow(book).to receive_message_chain(:reservations, :create).with(no_args).
        with(user: user, status: 'RESERVED').and_return(true)
      }

      it {
        expect(subject.reserve(book)).to be_truthy
      }
    end
  end
end
