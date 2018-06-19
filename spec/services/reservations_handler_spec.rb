require "rails_helper"

RSpec.describe ReservationsHandler, type: :service do
  let(:user) { User.new }
  let(:book) { Book.new }
  subject { described_class.new(user, book) }

  describe '#reserve' do

    before {
      allow(book).to receive(:can_be_reserved?).with(user).and_return(can_be_reserved)
  }

    context 'without available book' do
      let(:can_be_reserved) { false }
      it {
        expect(subject.reserve).to eq("Book is not available for reservation")
      }
    end

    context 'with available book' do
      let(:can_be_reserved) { true }

      before {
        allow(book).to receive_message_chain(:reservations, :create).with(no_args).
        with(user: user, status: 'RESERVED').and_return(true)
      }

      it {
        expect(subject.reserve).to be_truthy
      }
    end
  end

  describe '#take' do

    before {
      allow(book).to receive(:can_take?).with(user).and_return(can_be_taken)
    }

    context 'book cannot be taken' do
      let(:can_be_taken) { false }
      it {
        expect(subject.take).to eq("Book cannot be taken")
      }
    end

    context 'book can be taken' do

    end
  end
end
