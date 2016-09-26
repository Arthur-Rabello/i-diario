class ConceptualExamValue < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :conceptual_exam, except: :conceptual_exam_id

  belongs_to :conceptual_exam
  belongs_to :discipline

  validates :conceptual_exam, presence: true
  validates :discipline_id, presence: true

  validate :uniqueness_of_discipline

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
  def uniqueness_of_discipline
    if ConceptualExamValue.find_by(discipline_id: self.discipline_id, conceptual_exam_id: self.conceptual_exam_id).present?
      errors.add(:value, :already_taken_for_student)
    end
  end

end
