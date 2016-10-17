class AvaliationMultipleCreatorForm
  include ActiveModel::Model
  include I18n::Alchemy


  attr_accessor :test_setting_id, :unity_id, :discipline_id, :test_setting_test_id,
                :description, :weight, :observations, :school_calendar_id, :avaliations, :teacher_id

  validates :unity_id,             presence: true
  validates :discipline_id,        presence: true
  validates :school_calendar_id,   presence: true
  validates :test_setting_id,      presence: true
  validates :test_setting_test_id, presence: true, if: :fix_tests?
  validates :description,       presence: true, if: -> { !fix_tests? || allow_break_up? }
  validates :weight,            presence: true, if: :allow_break_up?
  validate :at_least_one_assigned_avaliation
  validate :validate_avaliations

  def initialize(attributes = {})
    @avaliations = []
    super
  end

  def valid?
    super && avaliations.select(&:include).all?(&:valid?)
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      avaliations.select(&:include).each(&:save!)
      self
    end
  end

  def test_setting
    return if test_setting_id.blank?
    @test_setting ||= TestSetting.find(test_setting_id)
  end

  def unity
    return if unity_id.blank?
    @unity ||= Unity.find(unity_id)
  end

  def discipline
    return if discipline_id.blank?
    @discipline ||= Discipline.find(discipline_id)
  end

  def test_setting_test
    return if test_setting_test_id.blank?
    @test_setting_test ||= TestSettingTest.find(test_setting_test_id)
  end

  def school_calendar
    SchoolCalendar.find_by(id: school_calendar_id)
  end

  def avaliations_attributes=(value)
    return unless value.present?

    @avaliations = []
    value.each do |avaliation_attributes|
      avaliation = Avaliation.new.localized
      avaliation.assign_attributes(
        include: avaliation_attributes.last['include'] == "1",
        classroom_id: avaliation_attributes.last['classroom_id'],
        test_date: avaliation_attributes.last['test_date'],
        classes: avaliation_attributes.last['classes'],
        test_setting_id: self.test_setting_id,
        unity_id: self.unity_id,
        discipline_id: self.discipline_id,
        test_setting_test_id: self.test_setting_test_id,
        description: self.description,
        weight: self.weight,
        observations: self.observations,
        school_calendar_id: self.school_calendar_id
      )
      @avaliations << avaliation
    end
  end

  def load_avaliations!(teacher_id)
    return unless discipline_id.present? && teacher_id.present? && unity_id.present?
    classrooms = Classroom.by_unity_and_teacher(unity_id, teacher_id).by_teacher_discipline(discipline_id).by_year(Date.today.year).ordered
    @avaliations = []
    classrooms.each do |classroom|
      @avaliations << Avaliation.new(
        classroom_id: classroom.id
      )
    end
  end

  protected

  def at_least_one_assigned_avaliation
    errors.add(:avaliations, :at_least_one_assigned_avaliation) if avaliations.select(&:include).blank?
  end

  def allow_break_up?
    test_setting_test && test_setting_test.allow_break_up
  end

  def fix_tests?
    return false if test_setting.nil?
    test_setting.fix_tests?
  end

  def validate_avaliations
    avaliations.select(&:include).all? do |avaliation|
      if !avaliation.valid?
        msg = avaliation.errors.full_messages.reject{|msg| msg.include?("Data da avaliação") || msg.include?("Aulas")}.first
        errors.add(:avaliations, msg) if msg
        avaliation.errors.add(:classroom, msg)
      end
    end
  end
end
