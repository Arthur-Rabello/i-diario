FactoryGirl.define do
  factory :exam_rule do
    sequence(:api_code, &:to_s)
    score_type ScoreTypes::NUMERIC
    frequency_type FrequencyTypes::GENERAL
    opinion_type OpinionTypes::DONT_USE
    recovery_type RecoveryTypes::DONT_USE
    final_recovery_maximum_score 10

    factory :exam_rule_by_discipline do
      frequency_type FrequencyTypes::BY_DISCIPLINE
    end

    factory :exam_rule_numeric_and_concept do
      score_type ScoreTypes::NUMERIC_AND_CONCEPT
      recovery_type RecoveryTypes::PARALLEL
    end

    factory :exam_rule_concept do
      score_type ScoreTypes::CONCEPT
    end
  end
end
