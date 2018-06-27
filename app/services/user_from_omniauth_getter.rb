class UserFromOmniauthGetter
  def initialize(access_token)
    @access_token = access_token
  end

  def perform
    data = access_token.info
    user = User.where(email: data['email']).first

    unless user
      user = User.create(
        email: data['email'],
        password: Devise.friendly_token[0,20]
      )
    end
    user
  end

  private

  attr_reader :access_token
end
