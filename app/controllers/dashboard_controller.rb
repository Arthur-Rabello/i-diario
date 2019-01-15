class DashboardController < ApplicationController
  def index
    fill_in_school_calendar_select_options
    fetch_current_school_calendar_step if @school_calendar_steps_options.any?
  end

  private

  def fill_in_school_calendar_select_options
    @school_calendar_steps_options = []
    current_school_calendar_steps.each do |school_calendar_step|
      option = []
      option << school_calendar_step.to_s
      option << school_calendar_step.id
      @school_calendar_steps_options << option
    end
  end

  def fetch_current_school_calendar_step
    @current_school_calendar_step = dashboard_current_school_calendar.step(Time.zone.today).try(:id)
  end

  def dashboard_current_school_calendar
    CurrentSchoolCalendarFetcher.new(current_user_unity, nil).fetch
  end

  def current_school_calendar_steps
    dashboard_current_school_calendar.try(:steps) || []
  end
end
