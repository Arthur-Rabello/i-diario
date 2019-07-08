require 'rails_helper'

RSpec.describe DailyNoteStudent, type: :model do
  let(:discipline) { create(:discipline) }
  let(:classroom) { create(:classroom) }
  let(:school_calendar) { create(:school_calendar_with_one_step, year: 2014) }
  let(:avaliation) { create(:avaliation, classroom: classroom, discipline: discipline, school_calendar: school_calendar, test_date: '2014-02-06') }
  let(:daily_note) { create(:daily_note, avaliation: avaliation) }
  subject(:daily_note_student) { build(:daily_note_student, daily_note: daily_note) }

  describe 'associations' do
    # FIXME: Ajustar junto com o refactor das factories
    xit { expect(subject).to belong_to(:daily_note) }
    xit { expect(subject).to belong_to(:student) }
  end

  describe 'validations' do
    # FIXME: Ajustar junto com o refactor das factories
    xit { expect(subject).to validate_presence_of(:student) }
    xit { expect(subject).to validate_presence_of(:daily_note) }

    context 'when test_setting with arithmetic calculation type tests' do
      let(:test_setting) { create(:test_setting, average_calculation_type: AverageCalculationTypes::ARITHMETIC) }
      let(:avaliation) { create(:avaliation, classroom: classroom, discipline: discipline, school_calendar: school_calendar, test_setting: test_setting, test_date: '2014-02-06') }
      let(:daily_note) { create(:daily_note, avaliation: avaliation) }
      subject { build(:daily_note_student, daily_note: daily_note) }

      # FIXME: Ajustar junto com o refactor das factories
      xit { expect(subject).to validate_numericality_of(:note).is_greater_than_or_equal_to(0)
                                                             .is_less_than_or_equal_to(subject.daily_note.avaliation.test_setting.maximum_score)
                                                             .allow_nil }
    end

    context 'when test_setting with sum calculation type and that do not allow break up' do
      let(:test_setting_with_sum_calculation_type) { FactoryGirl.create(:test_setting_with_sum_calculation_type) }
      let(:avaliation) { create(:avaliation, classroom: classroom,
                                             discipline: discipline,
                                             school_calendar: school_calendar,
                                             test_setting: test_setting_with_sum_calculation_type,
                                             test_setting_test: test_setting_with_sum_calculation_type.tests.first,
                                             weight: nil,
                                             test_date: '2014-02-06') }
      subject { build(:daily_note_student, daily_note: daily_note) }

      # FIXME: Ajustar junto com o refactor das factories
      xit { expect(subject).to validate_numericality_of(:note).is_greater_than_or_equal_to(0)
                                                             .is_less_than_or_equal_to(subject.daily_note.avaliation.test_setting_test.weight)
                                                             .allow_nil }
    end

    context 'when test_setting with sum calculation type and that allow break up' do
      let(:test_setting_with_sum_calculation_type_that_allow_break_up) { FactoryGirl.create(:test_setting_with_sum_calculation_type_that_allow_break_up) }
      let(:avaliation) { create(:avaliation, classroom: classroom,
                                             discipline: discipline,
                                             school_calendar: school_calendar,
                                             test_setting: test_setting_with_sum_calculation_type_that_allow_break_up,
                                             test_setting_test: test_setting_with_sum_calculation_type_that_allow_break_up.tests.first,
                                             weight: test_setting_with_sum_calculation_type_that_allow_break_up.tests.first.weight / 2,
                                             test_date: '2014-02-06') }
      subject { build(:daily_note_student, daily_note: daily_note) }

      # FIXME: Ajustar junto com o refactor das factories
      xit { expect(subject).to validate_numericality_of(:note).is_greater_than_or_equal_to(0)
                                                             .is_less_than_or_equal_to(subject.daily_note.avaliation.weight)
                                                             .allow_nil }
    end
  end
end
