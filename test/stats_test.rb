# frozen_string_literal: true

require "test_helper"

class StatsTest < Minitest::Test
  def test_empty_text
    stats = Humanizer::Stats.compute("")
    assert_equal 0, stats.word_count
  end

  def test_basic_stats
    text = "The quick brown fox jumps over the lazy dog. It was a sunny day."
    stats = Humanizer::Stats.compute(text)
    assert_equal 14, stats.word_count
    assert stats.unique_word_count > 0
    assert stats.sentence_count >= 2
  end

  def test_burstiness_high_for_varied_text
    text = "Short. This is a much longer sentence with many more words in it. No. Another long one follows with plenty of variation in the rhythm and cadence."
    stats = Humanizer::Stats.compute(text)
    assert stats.burstiness > 0.4, "Expected high burstiness for varied text, got #{stats.burstiness}"
  end

  def test_burstiness_low_for_uniform_text
    text = "Each sentence is about this long. Every sentence is about this long. All sentences are about this long. No sentence is much different."
    stats = Humanizer::Stats.compute(text)
    assert stats.burstiness < 0.3, "Expected low burstiness for uniform text, got #{stats.burstiness}"
  end

  def test_type_token_ratio
    text = "the the the the the cat cat cat dog dog"
    stats = Humanizer::Stats.compute(text)
    assert stats.type_token_ratio < 0.5, "Expected low TTR for repetitive text"
  end

  def test_syllable_estimation
    assert_equal 1, Humanizer::Stats.estimate_syllables("cat")
    assert_equal 1, Humanizer::Stats.estimate_syllables("the")
    assert Humanizer::Stats.estimate_syllables("comprehensive") >= 3
  end

  def test_sentence_splitting
    text = "Mr. Smith went to Washington. He met Dr. Jones there."
    sentences = Humanizer::Stats.split_sentences(text)
    # Should not split on "Mr." or "Dr."
    assert sentences.length <= 2, "Should handle abbreviations: got #{sentences.inspect}"
  end

  def test_uniformity_score_range
    text = "This is a test sentence. Another test sentence here. More text to analyze. Yet another one. And finally this one."
    stats = Humanizer::Stats.compute(text)
    score = Humanizer::Stats.uniformity_score(stats)
    assert score >= 0 && score <= 100
  end

  def test_ngram_repetition
    words = %w[the cat sat the cat sat the cat sat]
    rep = Humanizer::Stats.compute_ngram_repetition(words, 3)
    assert rep > 0, "Should detect repeated trigrams"
  end
end
