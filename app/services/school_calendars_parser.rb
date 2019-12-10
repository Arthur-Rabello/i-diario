class SchoolCalendarsParser
  def initialize(configuration)
    @configuration = configuration
  end

  def parse!
    school_calendars_from_api = api.fetch['escolas']
    build_school_calendars_to_synchronize(school_calendars_from_api)
  end

  def self.parse!(configuration)
    new(configuration).parse!
  end

  private

  attr_accessor :configuration

  def api
    IeducarApi::SchoolCalendars.new(configuration.to_api)
  end

  def build_school_calendars_to_synchronize(school_calendars_from_api)
    build_new_school_calendars(school_calendars_from_api) + build_existing_school_calendars(school_calendars_from_api)
  end

  def build_new_school_calendars(school_calendars_from_api)
    new_school_calendars_from_api = fetch_new_school_calendars_from_api(school_calendars_from_api)

    new_school_calendars_from_api.map do |school_calendar_from_api|
      unity = Unity.find_by(api_code: school_calendar_from_api['escola_id'])
      school_calendar = SchoolCalendar.new(
        unity: unity,
        year: school_calendar_from_api['ano'].to_i,
        number_of_classes: 4,
        step_type_description: school_calendar_from_api['descricao']
      )

      school_calendar_from_api['etapas'].each do |step|
        school_calendar.steps.build(
          step_number: step['etapa'],
          start_at: step['data_inicio'],
          end_at: step['data_fim'],
          start_date_for_posting: step['data_inicio'],
          end_date_for_posting: step['data_fim']
        )
      end

      steps_from_classrooms = get_school_calendar_classroom_steps(school_calendar_from_api['etapas_de_turmas'])
      steps_from_classrooms.each do |classroom_step|
        classroom = Classroom.find_by(api_code: classroom_step['turma_id'])

        classroom_calendar = SchoolCalendarClassroom.new(
          classroom_id: classroom.try(:id),
          step_type_description: classroom_step['descricao'],
          classroom_api_code: classroom_step['turma_id']
        )
        steps = []
        classroom_step['etapas'].each do |step|
          steps << SchoolCalendarClassroomStep.new(
            step_number: step['etapa'],
            start_at: step['data_inicio'],
            end_at: step['data_fim'],
            start_date_for_posting: step['data_inicio'],
            end_date_for_posting: step['data_fim']
          )
        end

        school_calendar.classrooms.build(classroom_calendar.attributes).classroom_steps.build(steps.collect{ |step| step.attributes })
      end

      school_calendar
    end
  end

  def fetch_new_school_calendars_from_api(school_calendars_from_api)
    school_calendars_from_api.select do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      Unity.exists?(api_code: unity_api_code) &&
        SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).none?
    end
  end

  def build_existing_school_calendars(school_calendars_from_api)
    school_calendars_to_synchronize = []
    existing_school_calendar_step_ids = []
    existing_school_calendars_from_api = fetch_existing_school_calendars_from_api(school_calendars_from_api)

    existing_school_calendars_from_api.each do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      school_calendar = SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).first
      school_calendar.step_type_description = school_calendar_from_api['descricao']

      school_calendar_from_api['etapas'].each_with_index do |step, index|
        school_calendar_step = school_calendar.steps[index]

        if school_calendar_step.present?
          existing_school_calendar_step_ids << school_calendar_step.id

          update_step_step_number(school_calendar, index, step)
          update_step_start_at(school_calendar, index, step)
          update_step_end_at(school_calendar, index, step)
        else
          school_calendar.steps.build(
            step_number: step['etapa'],
            start_at: step['data_inicio'],
            end_at: step['data_fim'],
            start_date_for_posting: step['data_inicio'],
            end_date_for_posting: step['data_fim']
          )
        end
      end

      school_calendar.steps.each do |step|
        step.mark_for_destruction unless existing_school_calendar_step_ids.include?(step.id)
      end

      existing_school_calendar_classroom_ids = []
      existing_school_calendar_classroom_step_ids = []

      steps_from_classrooms = get_school_calendar_classroom_steps(school_calendar_from_api['etapas_de_turmas'])
      steps_from_classrooms.each_with_index do |classroom_step, classroom_index|
        school_calendar_classroom = SchoolCalendarClassroom.by_classroom_api_code(classroom_step['turma_id']).first
        if school_calendar_classroom
          update_classroom_step_type_description(school_calendar.classrooms.detect { |c| c.id == school_calendar_classroom.id }, classroom_step['descricao'])
          existing_school_calendar_classroom_ids << school_calendar_classroom.id

          classroom_step['etapas'].each_with_index do |step, step_index|
            existing_school_calendar_classroom_step = school_calendar_classroom.classroom_steps[step_index]

            if existing_school_calendar_classroom_step.present?
              existing_school_calendar_classroom_step_ids << existing_school_calendar_classroom_step.id

              update_classrooms_step_step_number(school_calendar_classroom, step_index, step)
              update_classrooms_step_start_at(school_calendar.classrooms.detect { |c| c.id == school_calendar_classroom.id }, step_index, step)
              update_classrooms_step_end_at(school_calendar.classrooms.detect { |c| c.id == school_calendar_classroom.id }, step_index, step)
            else
              step = SchoolCalendarClassroomStep.new(
                step_number: step['etapa'],
                start_at: step['data_inicio'],
                end_at: step['data_fim'],
                start_date_for_posting: step['data_inicio'],
                end_date_for_posting: step['data_fim']
              )
              school_calendar.classrooms.detect { |c| c.id == school_calendar_classroom.id }.classroom_steps.build(step.attributes)
            end
          end
        else
          classroom = Classroom.find_by(api_code: classroom_step['turma_id'])

          classroom_calendar = SchoolCalendarClassroom.new(
            classroom_id: classroom.try(:id),
            step_type_description: classroom_step['descricao']
          )
          steps = []
          classroom_step['etapas'].each do |step|
            steps << SchoolCalendarClassroomStep.new(
              step_number: step['etapa'],
              start_at: step['data_inicio'],
              end_at: step['data_fim'],
              start_date_for_posting: step['data_inicio'],
              end_date_for_posting: step['data_fim']
            )
          end

          school_calendar.classrooms.build(classroom_calendar.attributes).classroom_steps.build(steps.collect{ |step| step.attributes })
        end
      end

      school_calendar.classrooms.each do |classroom|
        classroom.mark_for_destruction unless existing_school_calendar_classroom_ids.include?(classroom.id)

        classroom.classroom_steps.each do |step|
          step.mark_for_destruction unless existing_school_calendar_classroom_step_ids.include?(step.id)
        end
      end

      need_to_synchronize = school_calendar_need_synchronization?(school_calendar) || school_calendar_classroom_step_need_synchronization?(school_calendar.classrooms)
      school_calendars_to_synchronize << school_calendar if need_to_synchronize
    end

    school_calendars_to_synchronize
  end

  def fetch_existing_school_calendars_from_api(school_calendars_from_api)
    school_calendars_from_api.select do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      Unity.exists?(api_code: unity_api_code) &&
        SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).any?
    end
  end

  def update_step_step_number(school_calendar, index, step)
    return if school_calendar.steps[index].step_number == step['etapa'].to_i

    school_calendar.steps[index].step_number = step['etapa'].to_i
  end

  def update_step_start_at(school_calendar, index, step)
    if school_calendar.steps[index].start_at != Date.parse(step['data_inicio'])
      school_calendar.steps[index].start_at = step['data_inicio']
      school_calendar.steps[index].start_date_for_posting = step['data_inicio']
    end
  end

  def update_step_end_at(school_calendar, index, step)
    if school_calendar.steps[index].end_at != Date.parse(step['data_fim'])
      school_calendar.steps[index].end_at = step['data_fim']
      school_calendar.steps[index].end_date_for_posting = step['data_fim']
    end
  end

  def update_classrooms_step_step_number(school_calendar_classroom, step_index, step)
    return if school_calendar_classroom.classroom_steps[step_index].step_number == step['etapa'].to_i

    school_calendar_classroom.classroom_steps[step_index].step_number = step['etapa'].to_i
  end

  def update_classrooms_step_start_at(school_calendar_classroom, step_index, step)
    return unless school_calendar_classroom
    if school_calendar_classroom.classroom_steps[step_index].start_at != Date.parse(step['data_inicio'])
      school_calendar_classroom.classroom_steps[step_index].start_at = step['data_inicio']
      school_calendar_classroom.classroom_steps[step_index].start_date_for_posting = step['data_inicio']
    end
  end

  def update_classrooms_step_end_at(school_calendar_classroom, step_index, step)
    return unless school_calendar_classroom
    if school_calendar_classroom.classroom_steps[step_index].end_at != Date.parse(step['data_fim'])
      school_calendar_classroom.classroom_steps[step_index].end_at = step['data_fim']
      school_calendar_classroom.classroom_steps[step_index].end_date_for_posting = step['data_fim']
    end
  end

  def update_classroom_step_type_description(school_calendar_classroom, description)
    return unless school_calendar_classroom

    school_calendar_classroom.step_type_description = description
  end

  def school_calendar_need_synchronization?(school_calendar)
    school_calendar.changed? ||
    school_calendar.steps.any? do |step|
      step.new_record? || step.changed? || step.marked_for_destruction?
    end ||
    school_calendar.classrooms.any? do |school_calendar_classroom|
      school_calendar_classroom.new_record? || school_calendar_classroom.changed? || school_calendar_classroom.marked_for_destruction?
    end
  end

  def school_calendar_classroom_step_need_synchronization?(school_calendar_classroom)
    school_calendar_classroom.each do |classroom|
      return true if classroom.classroom_steps.any? do |classroom_step|
        classroom_step.new_record? || classroom_step.changed? || classroom_step.marked_for_destruction?
      end
    end

    false
  end

  def get_school_calendar_classroom_steps(classroom_steps)
    classroom_steps.nil? ? [] : classroom_steps
  end
end
