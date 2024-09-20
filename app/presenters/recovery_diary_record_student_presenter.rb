class RecoveryDiaryRecordStudentPresenter < BasePresenter
  def student_name_class
    name_class = 'multiline '

    if exempted_from_discipline
      name_class += 'exempted-student-from-discipline'
    elsif active.present? && !active
      name_class += 'inactive-student'
    elsif dependence.present? && dependence
      name_class += 'dependence-student'
    end

    name_class
  end

  def student_name
    binding.pry
    if exempted_from_discipline
      "****#{student}"
    elsif active.present? && !active
      "***#{student}"
    elsif dependence.present? && dependence
      "*#{student}"
    else
      student.to_s
    end
  end
end
