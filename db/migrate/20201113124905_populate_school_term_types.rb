class PopulateSchoolTermTypes < ActiveRecord::Migration
  def change
    SchoolTermType.create!(description: 'Anual', steps_number: 1)

    (
      SchoolCalendar.uniq.pluck(:step_type_description) +
      SchoolCalendarClassroom.uniq.pluck(:step_type_description)
    ).uniq.each do |step_type_description|
      step = SchoolCalendarStep.joins(:school_calendar)
                               .where(
                                 school_calendars: {
                                   step_type_description: step_type_description
                                 }
                               ).group(:school_calendar_id)
                               .count(:school_calendar_id)
                               &.first

      step ||= SchoolCalendarClassroomStep.joins(:school_calendar_classroom)
                                          .where(
                                            school_calendar_classrooms: {
                                              step_type_description: step_type_description
                                            }
                                          ).group(:school_calendar_classroom_id)
                                          .count(:school_calendar_classroom_id)
                                          &.first

      SchoolTermType.create!(description: step_type_description, steps_number: step.second)
    end
  end
end
