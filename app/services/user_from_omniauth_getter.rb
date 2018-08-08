class UserFromOmniauthGetter
  def initialize(access_token)
    @access_token = access_token
  end

  def perform
    User.where(provider: access_token.provider, uid:
      access_token.uid).first_or_create do |user|
      user.provider = access_token.provider
      user.uid = access_token.uid
      user.email = access_token.info.email
      user.password = Devise.friendly_token[0,20]
      user.token = access_token.credentials.token
      user.refresh_token = access_token.credentials.refresh_token
      user.save
    end
  end

  private

  attr_reader :access_token
end
