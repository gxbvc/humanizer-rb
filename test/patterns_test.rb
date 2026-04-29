# frozen_string_literal: true

require "test_helper"

class PatternsTest < Minitest::Test
  def test_all_28_patterns_exist
    assert_equal 28, Humanizer::Patterns::PATTERNS.length
  end

  def test_each_pattern_has_required_fields
    Humanizer::Patterns::PATTERNS.each do |p|
      assert p.id, "Pattern missing id"
      assert p.name, "Pattern missing name"
      assert p.category, "Pattern missing category"
      assert p.weight, "Pattern missing weight"
      assert p.detector, "Pattern missing detector"
    end
  end

  def test_tier_1_vocabulary_detected
    text = "We must delve into this comprehensive tapestry of innovation."
    result = Humanizer.analyze(text)
    vocab_finding = result.findings.find { |f| f[:pattern_id] == 7 }
    assert vocab_finding, "Should detect AI vocabulary"
    assert vocab_finding[:match_count] >= 3
  end

  def test_chatbot_artifacts_detected
    text = "Great question! Here is an overview. I hope this helps!"
    result = Humanizer.analyze(text)
    chatbot_finding = result.findings.find { |f| f[:pattern_id] == 19 }
    assert chatbot_finding, "Should detect chatbot artifacts"
  end

  def test_significance_inflation_detected
    text = "This serves as a testament to the evolving landscape and enduring legacy of innovation."
    result = Humanizer.analyze(text)
    sig_finding = result.findings.find { |f| f[:pattern_id] == 1 }
    assert sig_finding, "Should detect significance inflation"
  end

  def test_promotional_language_detected
    text = "This breathtaking, world-class destination is nestled in the heart of innovation."
    result = Humanizer.analyze(text)
    promo_finding = result.findings.find { |f| f[:pattern_id] == 4 }
    assert promo_finding, "Should detect promotional language"
  end

  def test_copula_avoidance_detected
    text = "The museum serves as a beacon. It boasts over 200 exhibits. The park features a lake."
    result = Humanizer.analyze(text)
    copula_finding = result.findings.find { |f| f[:pattern_id] == 8 }
    assert copula_finding, "Should detect copula avoidance"
  end

  def test_filler_phrases_detected
    text = "In order to succeed, due to the fact that we care, at this point in time we must act."
    result = Humanizer.analyze(text)
    filler_finding = result.findings.find { |f| f[:pattern_id] == 22 }
    assert filler_finding, "Should detect filler phrases"
  end

  def test_excessive_hedging_detected
    text = "This could potentially change everything. It might possibly work. They could conceivably succeed."
    result = Humanizer.analyze(text)
    hedge_finding = result.findings.find { |f| f[:pattern_id] == 23 }
    assert hedge_finding, "Should detect excessive hedging"
  end

  def test_curly_quotes_detected
    text = "\u201CThis is a quote,\u201D she said. \u2018Another one.\u2019"
    result = Humanizer.analyze(text)
    curly_finding = result.findings.find { |f| f[:pattern_id] == 18 }
    assert curly_finding, "Should detect curly quotes"
  end

  def test_registry
    registry = Humanizer::Patterns::Registry.new
    assert_equal 28, registry.all.length
    assert registry.find(7), "Should find pattern 7"
    assert registry.by_category(:language).length > 0
    assert registry.categories.include?(:language)
  end
end
