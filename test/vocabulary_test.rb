# frozen_string_literal: true

require "test_helper"

class VocabularyTest < Minitest::Test
  def test_tier_1_has_entries
    assert Humanizer::Vocabulary::TIER_1.length > 50
  end

  def test_tier_2_has_entries
    assert Humanizer::Vocabulary::TIER_2.length > 50
  end

  def test_tier_3_has_entries
    assert Humanizer::Vocabulary::TIER_3.length > 30
  end

  def test_ai_phrases_have_required_keys
    Humanizer::Vocabulary::AI_PHRASES.each do |phrase|
      assert phrase[:pattern].is_a?(Regexp), "AI phrase missing pattern"
      assert [1, 2, 3].include?(phrase[:tier]), "AI phrase has invalid tier: #{phrase[:tier]}"
      assert phrase[:fix].is_a?(String), "AI phrase missing fix"
    end
  end

  def test_function_words_has_entries
    assert_equal 100, Humanizer::Vocabulary::FUNCTION_WORDS.length
  end
end
