class GameQuestion < ActiveRecord::Base
  belongs_to :game
  belongs_to :question
  delegate :text, :level, to: :question, allow_nil: true

  validates :game, :question, presence: true
  validates :a, :b, :c, :d, inclusion: {in: 1..4}

  def variants
    {
      'a' => question.read_attribute("answer#{a}"),
      'b' => question.read_attribute("answer#{b}"),
      'c' => question.read_attribute("answer#{c}"),
      'd' => question.read_attribute("answer#{d}")
    }
  end

  def answer_correct?(letter)
    correct_answer_key == letter.to_s.downcase
  end

  def correct_answer_key
    {a => 'a', b => 'b', c => 'c', d => 'd'}[1]
  end

  def correct_answer
    variants[correct_answer_key]
  end
end
