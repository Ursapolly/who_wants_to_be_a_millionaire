require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) {FactoryGirl.create(:user)}
  let(:game_w_questions) {FactoryGirl.create(:game_with_questions, user: user)}

  context 'Game Factory' do
    it 'Game.create_game_for_user! new correct game' do
      generate_questions(60)
      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
          change(GameQuestion, :count).by(15).and(
              change(Question, :count).by(0)
          )
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq :in_progress
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game_mechanics' do
    it 'answer correct continues' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq :in_progress

      game_w_questions.answer_current_question!(q.correct_answer_key)
      expect(game_w_questions.current_level).to eq(level + 1)
      expect(game_w_questions.current_game_question).not_to eq q
      expect(game_w_questions.status).to eq :in_progress
      expect(game_w_questions.finished?).to be_falsey
    end

    it '.take_money! completes game' do
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq :in_progress
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.take_money!
      prize = game_w_questions.prize
      expect(prize).to be > 0

      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end

    it '.previous_level returns previous level' do
      game_w_questions.current_level = 2
      expect(game_w_questions.previous_level).to eq(1)
    end

    it '.current_game_question returns current question' do
      q = game_w_questions.game_questions[0]
      expect(game_w_questions.current_game_question).to eq q
      game_w_questions.current_level += 1
      q2 = game_w_questions.game_questions[1]
      expect(game_w_questions.current_game_question).to eq q2
    end
  end


  #правило трёх A:
  #arrange
  # act
  # assert

  describe '#answer_current_question!' do
    context 'when answer current question is correct' do
      let(:game_w_questions) do
        FactoryGirl.create :game_with_questions, current_level: 5
      end

      it 'returns true' do
        result = game_w_questions.answer_current_question!('d')
        expect(result).to be_truthy
      end

      it 'returns game status in_progress' do
        game_w_questions.answer_current_question!('d')
        expect(game_w_questions.status).to eq :in_progress
      end

      it 'switches level' do
        game_w_questions.answer_current_question!('d')
        expect(game_w_questions.current_level).to eq 6
      end

      it 'saves result' do
        game_w_questions.answer_current_question!('d')
        expect(game_w_questions.save!).to be_truthy
      end
    end

    context 'when answer is last and correct' do
      let(:game_w_questions) do
        FactoryGirl.create :game_with_questions, current_level: 14
      end

      it 'returns true' do
        result = game_w_questions.answer_current_question!('d')
        expect(result).to be_truthy
      end

      it 'gives money' do
        game_w_questions.answer_current_question!('d')
        expect(game_w_questions.prize).to eq 1_000_000
      end

      it 'returns game status won' do
        game_w_questions.answer_current_question!('d')
        expect(game_w_questions.status).to eq :won
      end
    end

    context 'when answer is incorrect' do
      let(:game_w_questions) do
        FactoryGirl.create :game_with_questions, current_level: 6
      end
      it 'returns false for answer' do
        result = game_w_questions.answer_current_question!('a')
        expect(result).to be_falsey
      end

      it 'returns the same level' do
        game_w_questions.answer_current_question!('a')
        expect(game_w_questions.current_level).to eq 6
      end

      it 'returns game status fail' do
        game_w_questions.answer_current_question!('a')
        expect(game_w_questions.status).to eq :fail
      end

      it 'gives money' do
        game_w_questions.answer_current_question!('a')
        expect(game_w_questions.prize).to eq 1_000
      end
    end


    context 'when timeout' do
      let(:game_w_questions) do
        FactoryGirl.create :game_with_questions, created_at: 1.hour.ago
      end

      it 'returns false for any answer' do
        result = game_w_questions.answer_current_question!('d')
        expect(result).to be_falsey
      end

      it 'returns game status timeout' do
        game_w_questions.answer_current_question!('d')
        expect(game_w_questions.status).to eq :timeout
      end
    end
  end

  context 'game.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it 'returns :fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq :fail
    end

    it 'returns :timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq :timeout
    end

    it 'returns :won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq :won
    end

    it 'returns :money' do
      expect(game_w_questions.status).to eq :money
    end
  end
end

