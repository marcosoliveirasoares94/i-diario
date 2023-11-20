class CopyDisciplineTeachingPlanService
  class CopyDisciplineTeachingPlanError < StandardError; end
  attr_reader :discipline_teaching_plan_id, :year, :unities_ids, :grades_ids

  def self.call(*params)
    new(*params).call
  end

  def initialize(
    discipline_teaching_plan_id,
    year,
    unities_ids,
    grades_ids
  )
    @discipline_teaching_plan_id = discipline_teaching_plan_id
    @year = year
    @unities_ids = unities_ids
    @grades_ids = grades_ids

    check_required_params
  end

  def call
    model_discipline_teaching_plan = DisciplineTeachingPlan.find(discipline_teaching_plan_id)
    model_teaching_plan = model_discipline_teaching_plan.teaching_plan
    discipline_id = model_discipline_teaching_plan.discipline_id
    thematic_unit = model_discipline_teaching_plan.thematic_unit

    fetch_contents_and_objectives(model_teaching_plan)

    new_discipline_teaching_plans = fetch_teacher_discipline_classrooms(
      model_teaching_plan,
      discipline_id,
      thematic_unit
    )

    new_discipline_teaching_plans
  end

  private

  def fetch_contents_and_objectives(teaching_plan)
    @content_ids = []
    @objective_ids = []

    @contents_created_at_position = {}
    @objectives_created_at_position = {}

    teaching_plan.contents_teaching_plans.each_with_index do |content_teaching_plan, index|
      @contents_created_at_position[content_teaching_plan.content_id] = index
      @content_ids << content_teaching_plan.content_id
    end

    teaching_plan.objectives_teaching_plans.each do |objective_teaching_plan, index|
      @objectives_created_at_position[objective_teaching_plan.objective_id] = index
      @objective_ids << objective_teaching_plan.objective_id
    end
  end

  def fetch_teacher_discipline_classrooms(teaching_plan, discipline_id, thematic_unit)
    new_discipline_teaching_plans = []
    teacher_grades = {}

    teacher_discipline_classrooms = TeacherDisciplineClassroom.includes(:teacher).where(
      year: year,
      discipline_id: discipline_id,
      grade_id: grades_ids
    )

    teacher_discipline_classrooms.each do |tdc|
      teacher_id = tdc.teacher_id
      grade_id = tdc.grade_id

      teacher_grades[teacher_id] ||= []

      next if teacher_grades[teacher_id].include?(grade_id)

      teacher_grades[teacher_id] << grade_id
    end

    unities_ids.each do |unity_id|
      teacher_grades.each do |key, values|
        values.each do |grade_id|
          new_discipline_teaching_plans << create_copies_discipline_teaching_plans(
            teaching_plan,
            discipline_id,
            key,
            grade_id,
            unity_id,
            thematic_unit
          )
        end
      end
    end

    new_discipline_teaching_plans
  end

  def create_copies_discipline_teaching_plans(
    teaching_plan,
    discipline_id,
    teacher_id,
    grade_id,
    unity_id,
    thematic_unit
  )
    copy_teaching_plan = teaching_plan.dup
    copy_teaching_plan.unity_id = unity_id
    copy_teaching_plan.grade_id = grade_id
    copy_teaching_plan.contents_created_at_position = @contents_created_at_position
    copy_teaching_plan.objectives_created_at_position = @objectives_created_at_position
    copy_teaching_plan.content_ids = @content_ids
    copy_teaching_plan.objective_ids = @objective_ids

    copy_teaching_plan.build_discipline_teaching_plan(
      discipline_id: discipline_id,
      thematic_unit: thematic_unit
    )

    copy_teaching_plan.teacher_id = teacher_id
    copy_teaching_plan.save!(validate: false)

    copy_teaching_plan.discipline_teaching_plan
  end

  def check_required_params
    required_params_missing = unities_ids.blank? ||
                              grades_ids.blank? ||
                              discipline_teaching_plan_id.blank? ||
                              year.blank?

    raise CopyDisciplineTeachingPlanError, 'Missing required parameters' if required_params_missing
  end
end
