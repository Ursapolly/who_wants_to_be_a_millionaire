class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :goto_game_in_progress!, only: [:create]
  before_action :set_game, except: [:create]
  before_action :redirect_from_finished_game!, except: [:create]

  def show
    @game_question = @game.current_game_question
  end

  def create
    begin
      @game = Game.create_game_for_user!(current_user)
      redirect_to game_path(@game), notice: I18n.t(
        'controllers.games.game_created',
        created_at: @game.created_at
      )
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => ex
      Rails.logger.error("Error creating game for user #{current_user.id}, " \
                         "msg = #{ex}. #{ex.backtrace}")
      redirect_to :back, alert: I18n.t('controllers.games.game_not_created')
    end
  end

  def answer
    @answer_is_correct = @game.answer_current_question!(params[:letter])
    @game_question = @game.current_game_question

    unless @answer_is_correct
      flash[:alert] = I18n.t(
        'controllers.games.bad_answer',
        answer: @game_question.correct_answer,
        prize: view_context.number_to_currency(@game.prize)
      )
    end

    if @game.finished?
      redirect_to user_path(current_user)
    else
      redirect_to game_path(@game)
    end
  end

  def take_money
    @game.take_money!
    redirect_to user_path(current_user), flash: {
      warning: I18n.t(
        'controllers.games.game_finished',
        prize: view_context.number_to_currency(@game.prize)
      )
    }
  end

  private

  def redirect_from_finished_game!
    if @game.finished?
      redirect_to user_path(current_user), alert: I18n.t(
        'controllers.games.game_closed',
        game_id: @game.id
      )
    end
  end

  def goto_game_in_progress!
    game_in_progress = current_user.games.in_progress.first

    unless game_in_progress.blank?
      redirect_to game_path(game_in_progress), alert: I18n.t(
        'controllers.games.game_not_finished'
      )
    end
  end

  def set_game
    @game = current_user.games.find_by(id: params[:id])

    if @game.blank?
      redirect_to root_path, alert: I18n.t(
        'controllers.games.not_your_game'
      )
    end
  end
end
