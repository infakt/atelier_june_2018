class Book < ApplicationRecord
  has_many :reservations
  has_many :borrowers, through: :reservations, source: :user
  belongs_to :category

  # statuses: AVAILABLE, TAKEN, RESERVED, EXPIRED, CANCELED, RETURNED

  def category_name
    category.try(:name)
  end

  def category_name=(name)
    self.category = Category.where(name: name).first_or_initialize
  end

  def can_take?(user)
    not_taken? && ( available_for_user?(user) || reservations.empty? )
  end

  def can_give_back?(user)
    reservations.find_by(user: user, status: 'TAKEN').present?
  end

  def can_reserve?(user)
    reservations.find_by(user: user, status: 'RESERVED').nil?
  end

  def available_reservation
    reservations.find_by(status: 'AVAILABLE')
  end

  def next_in_queue
    reservations.where(status: 'RESERVED').order(created_at: :asc).first
  end

  private

  def not_taken?
    reservations.find_by(status: 'TAKEN').nil?
  end

  def available_for_user?(user)
    if available_reservation.present?
      available_reservation.user == user
    else
      pending_reservations.nil?
    end
  end

  def pending_reservations
    reservations.find_by(status: 'PENDING')
  end
end
