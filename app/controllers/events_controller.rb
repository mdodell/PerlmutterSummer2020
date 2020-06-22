class EventsController < ApplicationController
  before_action :set_event, only: [:show, :attend, :unattend, :edit, :update, :destroy]
  before_action :authenticate_admin!, only: [:edit, :update, :destroy]
  before_action :authenticate_user!, only: [:index, :new, :show, :attend, :unattend]
  before_action :authenticate_event_type!, only: [:show]

  # GET /events
  # GET /events.json
  def index
    @events = Event.all
  end

  # GET /events/1
  # GET /events/1.json
  def show
  end

  def attend
    redirect_to toggle_attendance(current_user.id, @event.group.id, true, true)
  end

  def unattend
    redirect_to toggle_attendance(current_user.id, @event.group.id, false, true)
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
      #redirect_to modify_event_from_admin_form(params)
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        @event.group = Group.new(name: params['event']['title'], visible: false)
        @event.group.users = maintain_state(get_users_from_select(params['event']['group']), @event.group)
        if @event.group.users.count == 0
          @event.errors.add(:group, "must have users!")
          format.html { render :new }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        else
        flash['success'] = t('.success')
        if @event.published
          publish_event(@event)
        end
        format.html { redirect_to @event }
        format.json { render :show, status: :created, location: @event }
        end
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        @event.group.update(name: params['event']['title'], visible: false)
        @event.group.users = maintain_state(get_users_from_select(params['event']['group']), @event.group)
        if @event.group.users.count == 0
          @event.errors.add(:group, "must have users!")
          format.html { render :edit }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
        flash['success'] = t(".success")
        if @event.published
          publish_event(@event)
        end
        format.html { redirect_to @event}
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    if @event.published
      notify_delete_event(@event)
    end
    @event.destroy
    respond_to do |format|
      flash['success'] = t(".success")
      format.html { redirect_to events_url }
      format.json { head :no_content }
    end
  end

  def authenticate_event_type!
    if !@event.blank? && !current_user.admin && @event.eventType == "message"
      flash[:error] = t('global.invalid_action')
      redirect_to root_path
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:title, :description, :startDate, :startTime, :endDate, :endTime, :location, :eventType, :published)
    end
end
