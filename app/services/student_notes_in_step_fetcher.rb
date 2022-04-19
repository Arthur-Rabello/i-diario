class StudentNotesInStepFetcher
  include I18n::Alchemy

  def initialize(student)
    @student = student
  end

  def lowest_note_in_step(classroom_id, discipline_id, step_id)
    classroom = Classroom.find(classroom_id)
    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_discipline_id(discipline_id)
                            .by_step(classroom_id, step_id)
                            .ordered

    lowest_note = nil

    avaliations.each do |avaliation|
      score = DailyNoteStudent.by_student_id(student.id)
                              .by_avaliation(avaliation.id)
                              .first
                              .try(:recovered_note)

      next if score.nil?

      lowest_note = score if lowest_note.nil?

      if score < lowest_note
        lowest_note = score
      end
    end

    numeric_parser.localize(lowest_note)
  end

  private

  def numeric_parser
    @numeric_parser ||= I18n::Alchemy::NumericParser
  end

  attr_accessor :student, :school_calendar_step_id, :classroom_id, :discipline_id
end
