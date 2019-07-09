class CurrentTestSettingFetcher
  def initialize(school_calendar)
    @school_calendar = school_calendar
  end

  def fetch
    current_test_setting = TestSetting.find_by(
      exam_setting_type: ExamSettingTypes::GENERAL,
      year: @school_calendar.year
    )

    if current_test_setting.blank?
      school_term = SchoolTermConverter.convert(@school_calendar.step(Time.zone.today))
      current_test_setting = TestSetting.find_by(
        year: @school_calendar.year,
        school_term: school_term
      )
    end

    current_test_setting
  end
end
