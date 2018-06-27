require "rails_helper"

RSpec.describe ReservationsHandler, type: :service do
  let(:user) { User.new }
  let(:book) { Book.new }
  subject { described_class.new(user, book) }

  describe '#reserve' do
    before {
      allow(book).to receive_message_chain(:can_reserve?).with(user).and_return(can_reserve)
    }

    context 'without available book' do
      let(:can_reserve) { false }

      it { expect(subject.reserve).to eq('Book is not available for reservation') }
    end

    context 'with available book ' do
      let(:can_reserve) { true }
      before {
        allow(book).to receive_message_chain(:reservations, :create).with(no_args).
        with(user: user, status: 'RESERVED').and_return(true)
      }

      it { expect(subject.reserve).to be_truthy }
    end
  end

  describe '#take' do
    before {
      allow(book).to receive_message_chain(:can_take?).with(user).and_return(can_take)
    }

    context 'without available book' do
      let(:can_take) { false }

      it { expect(subject.take).to eq('Book can not be taken at the moment') }
    end

    context 'with available book' do
      let(:can_take) { true }

      before {
        allow(book).to receive_message_chain(:available_reservation, :present?).with(no_args).with(no_args).and_return(present)
      }

      context 'available reservation present' do
        let(:present) { true }

        before {
          allow(book).to receive_message_chain(:available_reservation, :update_attributes).with(no_args).with(status: 'TAKEN').and_return(true)
        }

        it { expect(subject.take).to be_truthy }
      end

      context 'available reservation not present' do
        let(:present) { false }

        before {
          allow(book).to receive_message_chain(:reservations, :create).with(no_args).with(user: user, status: 'TAKEN').and_return(true)
        }

        it { expect(subject.take).to be_truthy }
      end
    end
  end
end