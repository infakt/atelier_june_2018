require "rails_helper"

RSpec.describe ReservationsHandler, type: :service do
  let(:user) { User.new }
  let(:book) { Book.new }
  subject { described_class.new(user, book) }

  describe '#reserve' do

    before {
      allow(subject).to receive(:can_be_reserved?).and_return(result)
    }

    context 'without available book' do
      let(:result) { false }
      it {
        expect(subject.reserve).to eq('Book is not available for reservation')
      }
    end

    context 'with available book' do
      let(:result) { true }

      before {
        allow(book).to receive_message_chain(:reservations, :create).with(no_args).with(user: user, status: 'RESERVED').and_return(true)
      }

      it { expect(subject.reserve).to be_truthy }
    end
  end

  describe '#take' do

    before {
      allow(subject).to receive(:can_be_taken?).and_return(result)
    }

    context 'cannot be taken' do
      let(:result) { false }

      it { expect(subject.take).to eq(nil) }
    end

    context 'can be taken' do
      let(:result) { true }

      before {
        allow(book).to receive_message_chain(:available_reservation, :present?)
          .with(no_args).with(no_args)
          .and_return(was_taken)
      }

      context 'was taken before' do
        let(:was_taken) { true }

        before {
          allow(book).to receive_message_chain(:available_reservation, :update_attributes).with(no_args).with(status: 'TAKEN').and_return(true)
        }

        it { expect(subject.take).to be_truthy }
      end

      context 'was not taken before' do
        let(:was_taken) { false }

        before {
          allow(book).to receive_message_chain(:reservations, :create).with(no_args).with(user: user, status: 'TAKEN').and_return(true)
        }

        it { expect(subject.take).to be_truthy }
      end
    end
  end

  describe '#cancel_reservation' do

    before {
      allow(book).to receive_message_chain(:reservations, :where, :order, :first, :update_attributes).with(no_args).with(user: user, status: 'RESERVED').with(created_at: :asc).with(no_args).with(status: 'CANCELED').and_return(true)
    }

    it { expect(subject.cancel_reservation).to be_truthy }

  end

  describe '#next_in_queue' do

    before {
      allow(book).to receive_message_chain(:reservations, :where, :order, :first).and_return(true)
    }

    it { expect(subject.next_in_queue).to be_truthy }
  end

  describe '#give_back' do

    before {
      allow(book).to receive_message_chain(:reservations, :find_by, :update_attributes).with(no_args).with(status: 'TAKEN').with(status: 'RETURNED').and_return(true)

      allow(subject).to receive_message_chain(:next_in_queue, :present?).with(no_args).with(no_args).and_return(result)

      allow(subject).to receive_message_chain(:next_in_queue, :update_attributes).with(no_args).with(status: 'AVAILABLE').and_return(true)
    }

    context 'next_in_queue present' do
      let(:result) { true }
      it { expect(subject.give_back).to be_truthy }
    end

    context 'next_in_queue not present' do
      let(:result) { false }
      it { expect(subject.give_back).to be_falsey }
    end



  end

  describe '#can_be_taken?' do

    before {
      allow(subject).to receive(:not_taken?).with(no_args).and_return(is_free)
    }

    context 'is taken' do
      let(:is_free) { false }
      it { expect(subject.can_be_taken?).to be_falsey}
    end

    context 'is not taken' do
      let(:is_free) { true }

      before {
        allow(book).to receive(:available_for_user?).with(user).and_return(availibility)
        allow(book).to receive_message_chain(:reservations, :empty?).with(no_args).with(no_args).and_return(emptiness)
      }

      context 'book available and reservation empty' do
        let(:availibility) { true }
        let(:emptiness) { true }
        it { expect(subject.can_be_taken?).to be_truthy}
      end

      context 'book available but reservation not empty' do
        let(:availibility) { true }
        let(:emptiness) { false }
        it { expect(subject.can_be_taken?).to be_truthy}
      end

      context 'book not available but reservation empty' do
        let(:availibility) { false }
        let(:emptiness) { true }
        it { expect(subject.can_be_taken?).to be_truthy}
      end

      context 'book not available and reservation not empty' do
        let(:availibility) { false }
        let(:emptiness) { false }
        it { expect(subject.can_be_taken?).to be_falsey}
      end
    end
  end

  describe '#can_give_back?' do

    before {
      allow(book).to receive_message_chain(:reservations, :find_by, :present?).with(no_args).with(user: user, status: 'TAKEN').with(no_args).and_return(result)
    }

    context 'reservation present' do
      let(:result) { true }
      it { expect(subject.can_give_back?).to be_truthy }
    end

    context 'reservation not present' do
      let(:result) { false }
      it { expect(subject.can_give_back?).to be_falsey }
    end
  end

  describe '#can_be_reserved?' do
    before {
      allow(book).to receive_message_chain(:reservations, :find_by, :nil?).with(no_args).with(user: user, status: 'RESERVED').with(no_args).and_return(true)
    }
    it { expect(subject.can_be_reserved?).to be_truthy}
  end
end
