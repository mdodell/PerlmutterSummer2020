module EventsHelper

  def get_events(model)
    Kaminari.paginate_array(model.order(:startDate).reverse_order.select {|event| (event.users.exists?(current_user.id) && event.published? && event.use_app?) || current_user.admin? || current_user.moderator?}).page params[:page]
  end

  def with_urls(text)
    text.gsub(URI.regexp(["http", "https"]), '<a class="inline-url" href="\0">\0</a>')
  end

  def user_attending?(event)
    event_status = EventStatus.find_by(event_id: event.id, user_id: current_user.id)
    if event_status.attending?
      return true
    else
      return false
    end
  end

  def user_invited?(event)
    return EventStatus.find_by(event_id: event.id, user_id: current_user.id).present?
  end

  def get_event_html_header(event)
    if event.event?
      fa_icon = 'fa fa-calendar-alt'
      type = I18n.t("events.event")
    elsif event.info?
      fa_icon = 'fa fa-info-circle'
      type = I18n.t("events.info")
    else
      fa_icon = 'fa fa-comments'
      type = I18n.t("events.message")
    end
    TextHandler.new.process_fa(fa_icon, nil, "<span>#{type}</span>", nil).html_safe
  end

  def get_event_html_title(event)
    with_urls("#{event.title}").html_safe
  end

  def get_event_html_body(event, attending_count, is_on_show)
    attendance_display_html = ""
    users_html = ""
    if !moderator_signed_in?(current_user)
      status = EventStatus.find_by(user_id: current_user.id, event_id: event.id)
      if status.attending?
        attendance_display_html = I18n.t("global.others_count", count: (attending_count - 1).to_s, prefix: I18n.t("global.others_prefix"), suffix: I18n.t("global.attending").downcase)
        confirm_path = unattend_event_path(event)
      else
        attendance_display_html = I18n.t("global.others_count", count: attending_count.to_s, prefix: "", suffix: I18n.t("global.attending").downcase)
        confirm_path = attend_event_path(event)
      end
    else
      if is_on_show
        event.users.each do |user|
          users_html += "<p class='card-text pt-2'><strong>#{get_full_name(user)}</strong></p>" + get_user_html_body(user, EventStatus.find_by(user_id: user.id, event_id: event.id))
        end
      end
      attendance_display_html = "#{attending_count} #{I18n.t("global.attending").downcase}"
    end

    if event.event?
      attendance_display_html = "<p class='card-text'>#{TextHandler.new.process_fa("fa fa-user-circle", nil, attendance_display_html, nil)}</p>"
    else
      attendance_display_html = ""
    end

    "#{!event.description.blank? ?
         "<p class='card-text'><strong>#{I18n.t("events.description")}:</strong> #{with_urls(event.description)}</p>" :
         ""}
    #{!get_when_text(event).blank? ?
        "<p class='card-text'><strong>#{I18n.t("events.when")}:</strong> #{with_urls(get_when_text(event))}</p>" :
        ""}
    #{!event.location.blank? ?
        "<p class='card-text'><strong>#{I18n.t("events.where")}:</strong> #{with_urls(event.location)}</p>" :
        ""}
    #{attendance_display_html}
    #{users_html}"
      .html_safe
  end

  def get_event_html_buttons(event, is_on_show)
    if is_on_show
      tertiary_button = "#{link_to I18n.t("global.back"), :back, class: "btn btn-primary"}"
    else
      tertiary_button = "#{link_to I18n.t("global.show"), event, class: "btn btn-primary"}"
    end
    button_html = "<div class='text-center'>
                    <div class='btn-group btn-group-md' role='group'>"
    if moderator_signed_in?(current_user)
      button_html += "#{link_to I18n.t("global.delete"), event, class: "btn btn-danger", method: :delete, data: { confirm: I18n.t("global.are_you_sure") }}
      #{link_to I18n.t("global.edit"), edit_event_path(event), class: "btn btn-secondary"}
      #{tertiary_button}
                    </div>
                  </div>"
    else
      button_html += "#{tertiary_button}
                    </div>
                  </div>"
    end
    button_html.html_safe
  end

  ##
  # Toggles attendance of a given user in an event
  # user_id - a user id
  # event_id - an event id
  # attend - whether to mark the user attending or not attending
  # output_as_flash - whether to output response as a flash or as text to be parsed by Twilio
  def toggle_attendance(user_id, event_id, attend, output_as_flash)
    status = EventStatus.find_by(user_id: user_id, event_id: event_id)
    text_output = ""
    if !status.blank?
      if attend
        if !status.attending?
          status.attending!
          output_as_flash ? flash.notice = I18n.t('events.attending_success_response') : text_output = I18n.t('events.attending_success_response')
        else
          output_as_flash ? flash.alert = I18n.t('events.attending_failed_response') : text_output = I18n.t('events.attending_failed_response')
        end
      else
        if !status.not_attending?
          status.not_attending!
          output_as_flash ? flash.notice = I18n.t('events.not_attending_success_response') : text_output = I18n.t('events.not_attending_success_response')
        else
          output_as_flash ? flash.alert = I18n.t('events.not_attending_failed_response') : text_output = I18n.t('events.not_attending_failed_response')
        end
      end
    else
      output_as_flash ? flash.alert = I18n.t('global.invalid_input') : text_output = I18n.t('global.invalid_input')
    end
    output_as_flash ? events_path : text_output
  end

  ##
  # Returns an array mapping the number of users of an event to attending state
  # event - an event
  def get_attending_counts(event)
    attending_count = 0
    event.users.each do |user|
      status = EventStatus.find_by(user_id: user.id, event_id: event.id)
      if !status.blank? && status.attending?
        attending_count += 1
      end
    end
    attending_count
  end

  ##
  # Returns a parsed timeframe given an event
  # event - an event
  def get_when_text(event)
    start_text = DateService.new.convert_to_readable_date_time(event.startDate, event.startTime)
    end_text = DateService.new.convert_to_readable_date_time(event.endDate, event.endTime)
    if !start_text.blank? && !end_text.blank?
      "#{start_text}—#{end_text}"
    else
      "#{start_text}#{end_text}"
    end
  end

  ##
  # Returns a parsed payload of an event as text, separated by the proper separator for the contact method
  # event - an event
  # uses_email - whether this result will be sent in email or a text
  def get_event_text_params(event, uses_email)
    separator = (uses_email ? "<br>" : "\n")
    title_text = "#{I18n.t("events.title")}: #{event.title}#{separator}"
    description_text = "#{I18n.t("events.description")}: #{event.description}#{separator}"
    when_text = ""
    where_text = ""
    unless get_when_text(event).blank?
      when_text = "#{I18n.t("events.when")}: #{get_when_text(event)}#{separator}"
    end
    unless event.location.blank?
      where_text = "#{I18n.t("events.where")}: #{event.location}#{separator}"
    end
    "#{title_text}"\
    "#{description_text}"\
    "#{when_text}"\
    "#{where_text}"
  end

  ##
  # Sets delivery/acceptance state of a user given notification success
  # was_successful - whether notifying the user succeeded
  # event - an event
  # status - a status
  def set_new_state_after_notify(was_successful, event, status)
    unless status.attending?
      if was_successful
        if event.event?
          status.not_responded!
        else
          status.delivered!
        end
      else
        status.not_delivered!
      end
      status.save
    end
  end

  ##
  # Sends notification of an event to a given user to the proper contact method, updating their state
  # event - an event
  # user - a user
  # status - a status
  # contact - a contact type
  def handle_send_publish_event_notification(event, user, status, contact)
    # If a new contact, send as new event and update their state
    success = true
    if status.non_message? || status.not_delivered?
      if contact == "email"
        begin
          UserMailer.event_create_email(user, event).deliver
        rescue StandardError => e
          success = false
        end
      else
        if contact == "text"
          prompt = (event.event? ? t('texts.new_prompt', id: event.id, yes: t('texts.text_yes'), no: t('texts.text_no')) : "")
          success, error = TwilioHandler.new.send_text(user, t('texts.new_event', params: get_event_text_params(event, false), type: event.eventType, prompt: prompt))
        else
          prompt = (event.event? ? t('texts.new_prompt', id: event.id.to_s.chars.join(' '), yes: " #{t('texts.call_yes')} #{t('texts.pound')}", no: " #{t('texts.call_no')} #{t('texts.pound')}") : "")
          success, error = TwilioHandler.new.send_call(user, t('texts.new_event', params: get_event_text_params(event, false), type: event.eventType, prompt: prompt))
        end
      end
      # Otherwise, they aren't new, don't update their state, send as updated event
    else
      if event.notify?
        if contact == "email"
          UserMailer.event_update_email(user, event).deliver rescue user
        else
          if contact == "text"
            prompt = (event.event? ? t('texts.updated_prompt', id: event.id, yes: t('texts.text_yes'), no: t('texts.text_no')) : "")
            TwilioHandler.new.send_text(user, t('texts.updated_event', params: get_event_text_params(event, false), type: event.eventType.capitalize, prompt: prompt))
          else
            prompt = (event.event? ? t('texts.updated_prompt', id: event.id.to_s.chars.join(' '), yes: " #{t('texts.call_yes')} #{t('texts.pound')}", no: " #{t('texts.call_no')} #{t('texts.pound')}") : "")
            TwilioHandler.new.send_call(user, t('texts.updated_event', params: get_event_text_params(event, false), type: event.eventType.capitalize, prompt: prompt))
          end
        end
      end
    end
    success
  end

  ##
  # Kicks off the notification of an event to a given user, updating their state
  # event - an event
  # user - a user
  # status - a status
  def send_publish_event_notification(event, user, status)
    success = true
    if user.use_email? && user.confirmed? && event.use_email?
      success = handle_send_publish_event_notification(event, user, status, "email")
    end
    if user.use_text? && user.confirmed_text? && event.use_text?
      success = handle_send_publish_event_notification(event, user, status, "text")
    end
    if user.use_call? && user.confirmed_call? && event.use_call?
      success = handle_send_publish_event_notification(event, user, status, "call")
    end
    unless success
      status.not_delivered!
    end
    set_new_state_after_notify(success, event, status)
  end

  ##
  # Sends notification of a deleted event to a given user
  # event - an event
  # user - a user
  def send_delete_event_notification(event, user)
    if event.notify?
      if user.use_email? && user.confirmed? && event.use_email?
        UserMailer.event_delete_email(user, event).deliver rescue user
      end
      if user.use_text? && user.confirmed_text? && event.use_text?
        success, error = TwilioHandler.new.send_text(user, t('texts.deleted_event', params: get_event_text_params(event, false), type: event.eventType.capitalize))
      end
      if user.use_call? && user.confirmed_call? && event.use_call?
        success, error = TwilioHandler.new.send_call(user, t('texts.deleted_event', params: get_event_text_params(event, false), type: event.eventType.capitalize))
      end
    end
  end

  ##
  # Calls for notification of an event, either new/update if publishing and deletion otherwise
  # event - an event
  # is_being_published - whether the event is being published or not
  def handle_notify_event(event, is_being_published)
    event.users.each do |user|
      I18n.with_locale(user.get_locale) do
        status = EventStatus.find_by(user_id: user.id, event_id: event.id)
        if !status.blank? && !status.not_attending?
          if is_being_published
            send_publish_event_notification(event, user, status)
          else
            send_delete_event_notification(event, user)
          end
        end
      end
    end
  end

  ##
  # Returns the prefix for the event action
  # is_being_updated - whether the event is being updated or not
  # is_being_deleted - whether the event is being deleted or not
  def get_event_action_prefix(is_being_updated, is_being_deleted)
    if is_being_deleted
      I18n.t("global.deleted")
    else
      if is_being_updated
        I18n.t("global.updated")
      else
        I18n.t("global.new")
      end
    end
  end
end
