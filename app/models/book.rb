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

  def available_reservation
    reservations.find_by(status: 'AVAILABLE')
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

    private
end
