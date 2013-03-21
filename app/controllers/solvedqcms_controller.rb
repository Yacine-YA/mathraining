#encoding: utf-8
class SolvedqcmsController < ApplicationController
  before_filter :signed_in_user
  
  def create
    qcm = Qcm.find(params[:qcm_id])
    user = current_user
    link = Solvedqcm.new
    link.user_id = user.id
    link.qcm_id = qcm.id
    link.nb_guess = 1
    
    good_guess = true
    
    if qcm.many_answers
    
      if params[:ans]
        answer = params[:ans]
      else
        answer = {}
      end
    
      qcm.choices.each do |c|
        if answer[c.id.to_s]
          # Répondu vrai
          if !c.ok
            good_guess = false
          end
        else
          # Répondu faux
          if c.ok
            good_guess = false
          end
        end
      end
      
      if good_guess
        # Correct
        link.correct = true
        link.save
      else
        # Incorrect
        link.correct = false
        link.save
        
        qcm.choices.each do |c|
          if answer[c.id.to_s]
            link.choices << c
          end
        end
      end
      
    
    else
      if !params[:ans]
        flash[:error] = "Veuillez cocher une réponse."
        redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
      end
    
      rep = qcm.choices.where(:ok => true).first
      if rep.id == params[:ans].to_i
        link.correct = true
        link.save
      else
        link.correct = false
        link.save
        choice = Choice.find(params[:ans])
        link.choices << choice
      end
    end
    
   
    redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id)
  end
  
  def update
    qcm = Qcm.find(params[:qcm_id])
    user = current_user
    link = Solvedqcm.where(:user_id => user, :qcm_id => qcm).first
    link.nb_guess = link.nb_guess + 1
    
    good_guess = true
    
    if qcm.many_answers
    
      if params[:ans]
        answer = params[:ans]
      else
        answer = {}
      end
    
      qcm.choices.each do |c|
        if answer[c.id.to_s]
          # Répondu vrai
          if !c.ok
            good_guess = false
          end
        else
          # Répondu faux
          if c.ok
            good_guess = false
          end
        end
      end
      
      if good_guess
        # Correct
        link.correct = true
        link.save
        link.choices.clear
      else
        # Incorrect
        link.correct = false
        link.save
        link.choices.clear
        qcm.choices.each do |c|
          if answer[c.id.to_s]
            link.choices << c
          end
        end
      end
    
    else
      if !params[:ans]
        flash[:error] = "Veuillez cocher une réponse."
        redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
      end
      
      rep = qcm.choices.where(:ok => true).first
      if rep.id == params[:ans].to_i
        link.correct = true
        link.save
        link.choices.clear
      else
        link.correct = false
        link.save
        choice = Choice.find(params[:ans])
        link.choices.clear
        link.choices << choice
      end
    
    end
    
    redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id)
  end
  
end
