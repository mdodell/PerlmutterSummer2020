require 'cgi'

class StaticPagesController < ApplicationController
  before_action :authenticate_user!, only: [:form, :results]
  before_action :set_form_vars, only: [:form, :results]
  include StaticPagesHelper

  def home
    if user_signed_in?
      redirect_to events_path
    end
  end

  def faq
    unless faq_configured?
      flash.alert = "#{I18n.t('global.missing_input', types: I18n.t('global.menu.faq'))} #{admin_signed_in?(current_user) ? I18n.t('global.missing_input_admin_prompt_manual') : I18n.t('global.missing_input_user_prompt_manual')}"
      redirect_to root_path
    end
  end

  def contact
    unless contact_configured?
      flash.alert = "#{I18n.t('global.missing_input', types: I18n.t('global.menu.contact'))} #{admin_signed_in?(current_user) ? I18n.t('global.missing_input_admin_prompt_manual') : I18n.t('global.missing_input_user_prompt_manual')}"
      redirect_to root_path
    end
  end

  def contact_send
    success = true
    if !params[:email].blank?
      if !I18n.t("config.contact.email", :default => '').empty?
        emails = []
        emails.push(I18n.t('config.contact.email'))
        success, error = UserMailer.contact_org(params[:subject], params[:body], params[:name], params[:contact], emails).deliver
      end
      if !I18n.t("config.contact.phone", :default => '').empty?
        success, error = TwilioHandler.new.send_text_direct(I18n.t("config.contact.phone"), TextHandler.new.get_contact_message(params[:subject], params[:body], params[:name], params[:contact], false))
      end
    end
    if success
      flash.notice = I18n.t("global.model_created", type: I18n.t("global.message").downcase)
    else
      flash.alert = I18n.t("global.error_message", type: I18n.t("global.message").downcase)
    end
    redirect_to contact_path
  end

  def form
    unless form_configured?
      flash.alert = "#{I18n.t('global.missing_input', types: I18n.t('config.form_name'))} #{admin_signed_in?(current_user) ? I18n.t('global.missing_input_admin_prompt_manual') : I18n.t('global.missing_input_user_prompt_manual')}"
      redirect_to root_path
    end
  end

  def results
    if UserScore.find_by(user_id: current_user.id, created_at: (Time.now - 24.hours)..Time.now).present?
      flash.alert = I18n.t('user_score.creation_failed_response')
      redirect_to form_path
    else
      if @answered_questions
        begin
          score, max_score = @form.get_score(@answered_questions)
          subscores = @form.get_subscores
          user_score = UserScore.new(user_id: @user.id)
          if subscores.empty?
            user_score.subscores << Subscore.new(user_score_id: user_score.id,
                                                 name: "score",
                                                 score: score,
                                                 max_score: max_score)
          else
            subscores.each do |key, value|
              user_score.subscores << Subscore.new(user_score_id: user_score.id,
                                                   name: key,
                                                   score: value[0],
                                                   max_score: value[1])
            end
          end
          user_score.save
          @user.user_scores << user_score
          @user.save
          emails = []
          if @user.use_email? && @user.confirmed?
            emails.push(@user.email)
          end
          emails.push(I18n.t("config.smtp.smtp_username"))
          UserMailer.form_create_email(@user, @form, @answered_questions, emails).deliver
          flash.now.notice = I18n.t("global.model_created", type: I18n.t("config.form_name"))
        rescue StandardError => e
          puts(e)
          flash.now.alert = I18n.t("global.error_message", type: I18n.t("config.form_name"))
        end
      end
    end
  end

  private
  def set_form_vars
    @form = FormService.new
    @user = current_user
    @answered_questions = params
  end
end
