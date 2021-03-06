require 'json'
module UsersHelper

  def list_users_groups(user)
    user.groups.map{|group| group.name}.join(", ")
  end

  def get_full_name(user)
    [user.first_name, user.last_name].join(' ')
  end

  def get_user_role_info(user)
    if admin_signed_in?(user)
      fa_user_icon = 'fa fa-user-cog'
      fa_icon = 'fa fa-cogs'
      account_type = I18n.t("global.menu.admin")
    elsif moderator_signed_in?(user)
      fa_user_icon = 'fa fa-user-edit'
      fa_icon = 'fa fa-edit'
      account_type = I18n.t("global.menu.moderator")
    elsif !user.blank?
      fa_user_icon = 'fa fa-user'
      fa_icon = fa_user_icon
      account_type = I18n.t("global.user")
    else
      fa_user_icon = 'fa fa-user-secret'
      fa_icon = fa_user_icon
      account_type = I18n.t("global.menu.guest")
    end
    [fa_user_icon, fa_icon, account_type]
  end

  def get_user_html_header(user)
    fa_user_icon, fa_icon, account_type = get_user_role_info(user)
    TextHandler.new.process_fa(fa_user_icon, nil, "<span>#{account_type}</span>", nil).html_safe
  end

  def get_user_html_body(user, status)

    using_email = user.confirmed? && user.use_email?
    using_text = user.confirmed_text? && user.use_text?
    using_call = user.confirmed_call? && user.use_call?

    "#{
    if !user.phone_number.blank? && (using_text || using_call)
      "<p class='card-text'>
        #{ using_text ? "#{TextHandler.new.process_fa("fa fa-comments", nil, nil, nil)}" : ""}#{ using_call ? "#{TextHandler.new.process_fa("fa fa-phone-alt", nil, nil, nil)}" : ""}#{user.phone_number}
      </p>"
    else
      ""
    end}
    #{ !user.email.blank? && using_email ?
           "<p class='card-text'>
              #{TextHandler.new.process_fa("fa fa-envelope-open-text", nil, nil, nil)}#{user.email}
            </p>" :
           ""}
    #{ !status.blank? ?
           "<p class='card-text'>#{t("activerecord.enums.event_status.states.#{status.state}")}</p>" :
           "" }".html_safe
  end

  def get_user_html_buttons(user, is_on_show)

    if is_on_show
      tertiary_button = "#{link_to I18n.t("global.back"), :back, class: "btn btn-outline-primary"}"
    else
      tertiary_button = "#{link_to I18n.t("global.show"), users_show_path(user), class: "btn btn-outline-primary"}"
    end
    "<div class='text-center'>
      <div class='btn-group btn-group-md' role='group'>
        #{link_to I18n.t("global.delete"), user_delete_path(user), class: "btn btn-outline-primary", method: :delete, data: { confirm: I18n.t("global.are_you_sure") }}
        #{link_to I18n.t("global.edit"), "#", class: "btn btn-outline-primary"}
        #{tertiary_button}
      </div>
    </div>".html_safe
  end

  def promote_to_moderator(user)
    if current_user.moderator? || current_user.admin?
      user.moderator!
    end
  end

  def calculate_days_until_users_birthday(user)
    birthday = Date.new(Date.today.year, user.birthday.month, user.birthday.day)
    birthday += 1.year if Date.today > birthday
    (birthday - Date.today).to_i
  end

  def reset_filters
    queries = [:name_query, :group_query, :email_query, :phone_number_query, :date_query]
    queries.each { |query| session[query] = nil }
  end

  def destroy_user(user, redirect_path)
    respond_to do |format|
      user.destroy
      flash.notice = t('global.model_deleted', type: t('global.user').downcase)
      format.html { redirect_to redirect_path }
    end
  end

  def map_user_scores(user)
    map = user.user_scores.map do |score|
      [Date.new(score.created_at.year, score.created_at.month, score.created_at.day), score.get_total_score[:score].round()]
    end

    return map
  end

  def map_user_subscores(user)
    map = user.subscores.pluck(:name).uniq.map do |name|
      {name: name.capitalize,
       data: user.subscores.where(name: name).order(:created_at).map { |score| [Date.new(score.created_at.year, score.created_at.month, score.created_at.day).to_s, score[:score].round()] }
      }
    end
    return map
  end
end
