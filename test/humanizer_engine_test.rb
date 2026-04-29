# frozen_string_literal: true

require "test_helper"

class HumanizerEngineTest < Minitest::Test
  def test_auto_fix_curly_quotes
    result = Humanizer.auto_fix("\u201CHello,\u201D she said. \u2018Goodbye.\u2019")
    assert_equal '"Hello," she said. \'Goodbye.\'', result[:text]
    assert result[:fixes].any? { |f| f.include?("curly") }
  end

  def test_auto_fix_filler_phrases
    result = Humanizer.auto_fix("In order to succeed, we must act.")
    assert_equal "to succeed, we must act.", result[:text]
  end

  def test_auto_fix_chatbot_opening
    result = Humanizer.auto_fix("Great question! The answer is 42.")
    assert_equal "The answer is 42.", result[:text]
  end

  def test_auto_fix_chatbot_closing
    result = Humanizer.auto_fix("The answer is 42. I hope this helps!")
    assert_equal "The answer is 42.", result[:text]
  end

  def test_humanize_returns_priorities
    text = "Great question! We must delve into this comprehensive tapestry. In order to succeed, we leverage synergies. I hope this helps!"
    result = Humanizer.humanize(text)
    assert result[:critical].is_a?(Array)
    assert result[:important].is_a?(Array)
    assert result[:minor].is_a?(Array)
    assert result[:guidance].is_a?(Array)
    assert result[:score] > 0
  end

  def test_humanize_with_autofix
    text = "In order to understand this, we must utilize our resources."
    result = Humanizer.humanize(text, autofix: true)
    assert result[:autofix], "Should include autofix results"
    assert result[:autofix][:text].include?("to understand")
    refute result[:autofix][:text].include?("In order to")
  end
end
