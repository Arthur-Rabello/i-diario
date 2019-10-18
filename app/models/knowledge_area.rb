class KnowledgeArea < ActiveRecord::Base
  include Discardable

  acts_as_copy_target

  audited

  include Audit

  has_many :disciplines, dependent: :destroy
  has_and_belongs_to_many :knowledge_area_content_records

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  default_scope -> { kept }

  scope :by_unity, lambda { |unity| by_unity(unity) }
  scope :by_teacher, lambda { |teacher| by_teacher(teacher) }
  scope :by_classroom_id, lambda { |classroom_id|
    joins(disciplines: :teacher_discipline_classrooms)
      .where(teacher_discipline_classrooms: { classroom_id: classroom_id })
      .uniq
  }
  scope :by_grade, lambda { |grade| by_grade(grade) }
  scope :by_discipline_id, lambda { |discipline_id| joins(:disciplines).where(disciplines: { id: discipline_id }) }
  scope :ordered, -> { order(arel_table[:description].asc) }

  def to_s
    description
  end

  private

  def self.by_unity(unity)
    joins(:disciplines).joins(
        arel_table.join(TeacherDisciplineClassroom.arel_table)
          .on(
            TeacherDisciplineClassroom.arel_table[:discipline_id]
              .eq(Discipline.arel_table[:id])
          )
          .join_sources
      )
      .joins(
        arel_table.join(Classroom.arel_table)
          .on(
            Classroom.arel_table[:id]
              .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
          )
          .join_sources
      )
      .where(classrooms: { unity_id: unity })
      .uniq
  end

  def self.by_teacher(teacher)
    joins(:disciplines).joins(
        arel_table.join(TeacherDisciplineClassroom.arel_table)
          .on(
            TeacherDisciplineClassroom.arel_table[:discipline_id]
              .eq(Discipline.arel_table[:id])
          )
          .join_sources
      )
      .where(teacher_discipline_classrooms: { teacher_id: teacher })
      .uniq
  end

  def self.by_grade(grade)
    joins(:disciplines).joins(
        arel_table.join(TeacherDisciplineClassroom.arel_table)
          .on(
            TeacherDisciplineClassroom.arel_table[:discipline_id]
              .eq(Discipline.arel_table[:id])
          )
          .join_sources
      )
      .joins(
        arel_table.join(Classroom.arel_table)
          .on(
            Classroom.arel_table[:id]
              .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
          )
          .join_sources
      )
      .where(classrooms: { grade_id: grade })
      .uniq
  end
end
