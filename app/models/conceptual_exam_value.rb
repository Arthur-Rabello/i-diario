class ConceptualExamValue < ActiveRecord::Base

  acts_as_copy_target

  audited associated_with: :conceptual_exam, except: :conceptual_exam_id

  belongs_to :conceptual_exam
  belongs_to :discipline

  validates :conceptual_exam, presence: true
  validates :discipline_id, presence: true

  def self.active(join_conceptual_exam = true)
    scoped = if join_conceptual_exam
       joins(:conceptual_exam)
    else
      all
    end

    scoped.active_query
  end

  def self.ordered
    joins(
      arel_table.join(KnowledgeArea.arel_table, Arel::Nodes::OuterJoin)
        .on(KnowledgeArea.arel_table[:id].eq(arel_table[:discipline_id]))
        .join_sources
    )
    .order(KnowledgeArea.arel_table[:description])
  end

  def mark_as_invisible
    @marked_as_invisible = true
  end

  def marked_as_invisible?
    @marked_as_invisible
  end

  private

  def self.active_query
    differentiated_exam_rules = ExamRule.arel_table.alias('differentiated_exam_rules')

    joins(
      arel_table.join(TeacherDisciplineClassroom.arel_table).
        on(TeacherDisciplineClassroom.arel_table[:classroom_id].eq(ConceptualExam.arel_table[:classroom_id]).
          and(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(arel_table[:discipline_id]))).join_sources,
      arel_table.join(Classroom.arel_table).
        on(Classroom.arel_table[:id].eq(ConceptualExam.arel_table[:classroom_id])).join_sources,
      arel_table.join(ExamRule.arel_table).
        on(ExamRule.arel_table[:id].eq(Classroom.arel_table[:exam_rule_id])).join_sources,
      arel_table.join(Student.arel_table, Arel::Nodes::OuterJoin).
        on(Student.arel_table[:id].eq(ConceptualExam.arel_table[:student_id]).
          and(Student.arel_table[:uses_differentiated_exam_rule].eq(true))).join_sources,
      arel_table.join(differentiated_exam_rules, Arel::Nodes::OuterJoin).
        on(differentiated_exam_rules[:id].eq(ExamRule.arel_table[:differentiated_exam_rule_id])).join_sources
    ).where(
      ExamRule.arel_table[:score_type].eq(Discipline::SCORE_TYPE_FILTERS[:concept][:score_type_target]).
        or(
          ExamRule.arel_table[:score_type].eq(Discipline::SCORE_TYPE_FILTERS[:concept][:score_type_numeric_and_concept]).
          and(TeacherDisciplineClassroom.arel_table[:score_type].eq(Discipline::SCORE_TYPE_FILTERS[:concept][:discipline_score_type_target]))
        ).or(
          differentiated_exam_rules[:score_type].eq(Discipline::SCORE_TYPE_FILTERS[:concept][:score_type_target]).
          and(Student.arel_table[:id].not_eq(nil))
        )
      ).uniq
  end
end
