class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  enum role: %i[user moderator admin]
  has_many :group_memberships
  has_many :groups, :through => :group_memberships
  has_many :event_statuses
  has_many :events, :through => :event_statuses
  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_confirmation_of :password
  validate :check_if_email_or_phone_entered?
  validate :format_phone_number
  validates_uniqueness_of :phone_number, conditions: -> {where.not(:phone_number => '')}
  after_save :send_phone_confirmation
  include ApplicationHelper

  def email_required?
    false
  end

  def check_if_email_or_phone_entered?
    if email.blank? && phone_number.blank?
      errors.add(:email, "must have an email or a phone number!")
    end
  end

  def get_locale
    yielded_locale = yield_locale_from_available(self.locale)
    yielded_locale.blank? ? I18n.locale : yielded_locale
  end

  private

  def format_phone_number
    unless phone_number.blank?
      valid_number, error = TwilioHandler.new.get_valid_phone_number(phone_number)
      if error.blank?
        self.phone_number = valid_number
      elsif
        errors.add(:phone_number, I18n.t('global.invalid_input'))
      else
        errors.add(:phone_number, error['message'])
      end
    end
  end

  def send_phone_confirmation
    ApplicationController.helpers.send_confirmation_text(self)
  end

end
