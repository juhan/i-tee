class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :ldap_authenticatable, #:registerable,
         :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, 
        :password_confirmation, :remember_me, :keypair, :token_expires
  
  has_many :vms, :dependent => :destroy
  has_many :lab_users, :dependent => :destroy
  validates_format_of :username, :with => /^[[:alnum:]]+$/, :message => "can only be alphanumeric with no spaces"
  
  def admin?
    return ITee::Application.config.admins.include?(username)
  end

  def manager?
    return ITee::Application.config.managers.include?(username)
  end

  # find first user that has the given token
  def self.find_by_token(token)
    return User.find(:first, :conditions=>["authentication_token=?", token])
  end


end
