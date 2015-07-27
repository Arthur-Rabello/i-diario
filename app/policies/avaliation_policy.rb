class AvaliationPolicy < ApplicationPolicy
  def edit?
    Avaliation.teacher_avaliations(@user.teacher.id, @record.classroom_id, @record.discipline_id).any? { |avaliation| avaliation.id.eql?(@record.id) }
  end
end
