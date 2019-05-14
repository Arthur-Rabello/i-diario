class AbsenceJustification < ActiveRecord::Base
  include Audit
  include Filterable
  include Discardable
  include TeacherRelationable

  teacher_relation_columns only: [:classroom, :discipline]

  acts_as_copy_target

  audited

  before_destroy :valid_for_destruction?
  before_destroy :remove_attachments, if: :valid_for_destruction?

  belongs_to :student
  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar
  belongs_to :teacher

  has_many :absence_justification_attachments, dependent: :destroy

  accepts_nested_attributes_for :absence_justification_attachments, allow_destroy: true

  validates_date :absence_date, :absence_date_end
  validates :teacher,          presence: true
  validates :student_id,       presence: true
  validates :unity,            presence: true
  validates :classroom_id,     presence: true
  validates :school_calendar,  presence: true
  validates :absence_date_end, presence: true, school_calendar_day: true, posting_date: true
  validates :absence_date,     presence: true, school_calendar_day: true, posting_date: true
  validates :discipline_id,    presence: true,
                               if: :frequence_type_by_discipline?
  validates :justification,    presence: true

  validate :period_absence
  validate :no_retroactive_dates

  default_scope -> { kept }

  scope :ordered, -> { order(absence_date: :desc) }
  scope :by_teacher, ->(teacher_id) { where(teacher_id: teacher_id)  }
  scope :by_classroom, ->(classroom_id) { where('classroom_id = ? OR classroom_id IS NULL', classroom_id) }
  scope :by_student, lambda { |student_name|
    joins(:student).where(
      "(unaccent(students.name) ILIKE unaccent('%#{student_name}%') or
        unaccent(students.social_name) ILIKE unaccent('%#{student_name}%'))"
    )
  }
  scope :by_discipline_id, ->(discipline_id) { where(discipline_id: discipline_id) }
  scope :by_student_id, ->(student_id) { where(student_id: student_id) }
  scope :by_date_range, lambda { |absence_date, absence_date_end|
    where('(NOT (absence_date > ? OR absence_date_end < ?))', absence_date_end, absence_date)
  }
  scope :by_unity, ->(unity) { where('unity_id = ? OR unity_id IS NULL', unity) }
  scope :by_school_calendar, ->(school_calendar) { where('school_calendar_id = ? OR school_calendar_id IS NULL', school_calendar) }
  scope :by_date, ->(date) { by_date_query(date) }
  scope :by_school_calendar_report, ->(school_calendar) { where(school_calendar: school_calendar)  }

  private

  def self.by_date_query(date)
    date = date.to_date
    where(
      AbsenceJustification.arel_table[:absence_date]
      .lteq(date)
      .and(AbsenceJustification.arel_table[:absence_date_end].gteq(date))
    )
  end

  def no_retroactive_dates
    return if absence_date.nil? || absence_date_end.nil?

    if absence_date > absence_date_end
      errors.add(:absence_date, 'não pode ser maior que a Data final')
      errors.add(:absence_date_end, 'deve ser maior ou igual a Data inicial')
    end
  end

  def period_absence
    absence_justifications = AbsenceJustification.by_classroom(classroom)
                                                 .by_student_id(student_id)
                                                 .by_discipline_id(discipline_id)
                                                 .by_date_range(absence_date, absence_date_end)

    absence_justifications = absence_justifications.where.not(id: id) if persisted?

    if absence_justifications.any?
      errors.add(:base, :discipline_period_absence) if frequence_type_by_discipline?
      errors.add(:base, :general_period_absence, teacher: absence_justifications.first.teacher.name) unless frequence_type_by_discipline?
      errors.add(:absence_date, :taken)
      errors.add(:absence_date_end, :taken)
    end
  end

  def frequence_type_by_discipline?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, teacher)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      valid?
      forbidden_error = I18n.t('errors.messages.not_allowed_to_post_in_date')
      !(errors[:absence_date_end].include?(forbidden_error) || errors[:absence_date].include?(forbidden_error))
    end
  end

  def remove_attachments
    absence_justification_attachments.each(&:destroy)
  end

  private_class_method :by_date_query
end
