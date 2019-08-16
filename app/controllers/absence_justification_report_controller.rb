class AbsenceJustificationReportController < ApplicationController
  before_action :require_current_teacher

  def form
    @absence_justification_report_form = AbsenceJustificationReportForm.new
    @absence_justification_report_form.unity_id = current_user_unity.id
    @absence_justification_report_form.school_calendar_year = current_school_calendar
    @absence_justification_report_form.current_teacher_id = current_teacher
  end

  def report
    @absence_justification_report_form = AbsenceJustificationReportForm.new(resource_params)
    @absence_justification_report_form.unity_id = current_user_unity.id
    @absence_justification_report_form.school_calendar_year = current_school_calendar
    @absence_justification_report_form.current_teacher_id = current_teacher

    if @absence_justification_report_form.valid?
      fetch_absences
      absence_justification_report = AbsenceJustificationReport.build(current_entity_configuration,
                                                                      @absence_justifications,
                                                                      @absence_justification_report_form)

      send_pdf(t('routes.absence_justification'), absence_justification_report.render)
    else
      clear_invalid_dates
      render :form
    end
  end

  private

  def fetch_absences
    author_type = (params[:absence_justification_report_form] || []).delete(:author)

    if @absence_justification_report_form.frequence_type_by_discipline?
      @absence_justifications = AbsenceJustification.by_author(author_type, current_teacher)
                                                    .by_unity(current_user_unity.id)
                                                    .by_school_calendar_report(current_school_calendar)
                                                    .by_classroom(@absence_justification_report_form.classroom_id)
                                                    .by_disciplines(@absence_justification_report_form.discipline_ids)
                                                    .by_date_range(@absence_justification_report_form.absence_date, @absence_justification_report_form.absence_date_end)
                                                    .uniq
                                                    .order(absence_date: :asc)
    else
      @absence_justifications = AbsenceJustification.by_author(author_type, current_teacher)
                                                    .by_unity(current_user_unity.id)
                                                    .by_school_calendar_report(current_school_calendar)
                                                    .by_classroom(@absence_justification_report_form.classroom_id)
                                                    .by_date_range(@absence_justification_report_form.absence_date, @absence_justification_report_form.absence_date_end)
                                                    .order(absence_date: :asc)
    end
  end

  def resource_params
    parameters = params.require(:absence_justification_report_form).permit(
      :unity,
      :classroom_id,
      :discipline_ids,
      :absence_date,
      :absence_date_end,
      :school_calendar_year,
      :current_teacher_id,
      :author
    )

    parameters[:discipline_ids] = parameters[:discipline_ids].split(',')

    parameters
  end

  def clear_invalid_dates
    begin
      resource_params[:absence_date].to_date
    rescue ArgumentError
      @absence_justification_report_form.absence_date = ''
    end

    begin
      resource_params[:absence_date_end].to_date
    rescue ArgumentError
      @absence_justification_report_form.absence_date_end = ''
    end
  end
end
