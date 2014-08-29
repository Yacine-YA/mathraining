#encoding: utf-8
class ExercisesController < QuestionsController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus,
    :order_plus, :put_online, :explanation, :update_explanation]
  before_filter :root_user, only: [:destroy]

  def new
    @chapter = Chapter.find(params[:chapter_id])
    @exercise = Exercise.new
  end

  def edit
    @exercise = Exercise.find(params[:id])
    if !@exercise.decimal
      @exercise.answer = @exercise.answer.to_i
    end
  end

  def create
    @chapter = Chapter.find(params[:chapter_id])
    @exercise = Exercise.new
    if @chapter.online
      @exercise.online = false
    else
      @exercise.online = true
    end
    
    @exercise.chapter_id = params[:chapter_id]
    @exercise.statement = params[:exercise][:statement]
    @exercise.level = params[:exercise][:level]
    @exercise.explanation = ""
    if params[:exercise][:decimal] == '1'
      @exercise.decimal = true
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_f
    else
      @exercise.decimal = false
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_i
    end
    before = 0
    before2 = 0
    if Exercise.exists?(["chapter_id = ?", params[:chapter_id]])
      need = Exercise.where("chapter_id = ?", params[:chapter_id]).order('position').reverse_order.first
      before = need.position
    end
    if Qcm.exists?(["chapter_id = ?", params[:chapter_id]])
      need = Qcm.where("chapter_id = ?", params[:chapter_id]).order('position').reverse_order.first
      before2 = need.position
    end
    @exercise.position = maximum(before, before2)+1
    @chapter = Chapter.find(params[:chapter_id])
    if @exercise.save
      flash[:success] = "Exercice ajouté."
      redirect_to chapter_path(@chapter, :type => 2, :which => @exercise.id)
    else
      render 'new'
    end
  end

  def update
    @exercise = Exercise.find(params[:id])
    @exercise.statement = params[:exercise][:statement]

    unless @exercise.chapter.online && @exercise.online
      if params[:exercise][:decimal] == '1'
        @exercise.decimal = true
      else
        @exercise.decimal = false
      end
      
      @exercise.level = params[:exercise][:level]
    end

    if @exercise.decimal
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_f unless @exercise.chapter.online && @exercise.online
    else
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_i unless @exercise.chapter.online && @exercise.online
    end
    
    
    if @exercise.save
      flash[:success] = "Exercice modifié."
      redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id)
    else
      render 'edit'
    end
  end

  def destroy
    @chapter = @exercise.chapter
    if @exercise.online && @exercise.chapter.online
      @exercise.destroy
      User.all.each do |user|
        point_attribution(user)
      end
    else
      @exercise.destroy
    end
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end

  def order_minus
    @exercise = Exercise.find(params[:exercise_id])
    order_op(true, true, @exercise)
  end

  def order_plus
    @exercise = Exercise.find(params[:exercise_id])
    order_op(false, true, @exercise)
  end

  def put_online
    @exercise = Exercise.find(params[:exercise_id])
    @exercise.online = true
    @exercise.save
    redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id)
  end

  def explanation
    @exercise = Exercise.find(params[:exercise_id])
  end

  def update_explanation
    @exercise = Exercise.find(params[:exercise_id])
    @exercise.explanation = params[:exercise][:explanation]
    if @exercise.save
      flash[:success] = "Explication modifiée."
      redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id)
    else
      render 'explanation'
    end
  end

  private

  def admin_user
    redirect_to root_path unless current_user.sk.admin?
  end

  def root_user
    @exercise = Exercise.find(params[:id])
    redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id) if (!current_user.sk.root && @exercise.online && @exercise.chapter.online)
  end

  def maximum(a, b)
    if a > b
      return a
    else
      return b
    end
  end

  def point_attribution(user)
    user.point.rating = 0
    partials = user.pointspersections
    partial = Array.new
    
    Section.all.each do |s|
      partial[s.id] = partials.where(:section_id => s.id).first
      if partial[s.id].nil?
        newpoint = Pointspersection.new
        newpoint.points = 0
        newpoint.section_id = s.id
        user.pointspersections << newpoint
        partial[s.id] = user.pointspersections.where(:section_id => s.id).first
      end
      partial[s.id].points = 0
    end

    user.solvedexercises.each do |e|
      if e.correct
        exo = e.exercise
        pt = exo.value

        if !exo.chapter.section.fondation? # Pas un fondement
          user.point.rating = user.point.rating + pt
        end

        partial[exo.chapter.section.id].points = partial[exo.chapter.section.id].points + pt
      end
    end

    user.solvedqcms.each do |q|
      if q.correct
        qcm = q.qcm
        pt = qcm.value

        if !qcm.chapter.section.fondation? # Pas un fondement
          user.point.rating = user.point.rating + pt
        end

        partial[qcm.chapter.section.id].points = partial[qcm.chapter.section.id].points + pt
      end
    end

    user.solvedproblems.each do |p|
      problem = p.problem
      pt = problem.value

      if !problem.section.fondation? # Pas un fondement
        user.point.rating = user.point.rating + pt
      end

      partial[problem.section.id].points = partial[problem.section.id].points + pt
    end

    user.point.save
    Section.all.each do |s|
      partial[s.id].save
    end

  end
end
