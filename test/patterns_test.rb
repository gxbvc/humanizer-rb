# frozen_string_literal: true

require "test_helper"

class PatternsTest < Minitest::Test
  def test_all_32_patterns_exist
    assert_equal 32, Humanizer::Patterns::PATTERNS.length
  end

  def finding_for(text, id)
    Humanizer.analyze(text).findings.find { |f| f[:pattern_id] == id }
  end

  def test_inanimate_subject_with_animate_verb_detected
    text = "The parser swallows that error. Then `retry()` thinks the job worked. The queue wants a fresh token."
    finding = finding_for(text, 30)
    assert finding, "Should detect inanimate subjects with animate verbs"
    assert_equal 3, finding[:match_count]
  end

  def test_inanimate_subject_ignores_people_and_code_doc_verbs
    text = "The engineer thinks the plan is fine. The function expects a string and returns a hash. My dad wants coffee."
    assert_nil finding_for(text, 30)
  end

  def test_reduced_object_relatives_need_three_hits
    two = "The route we took was slow. The part you wanted costs forty dollars."
    assert_nil finding_for(two, 31), "Two reduced relatives is normal human writing"

    three = "The approach we chose is slow. The state you set was lost. The test I added passes. Ship it."
    finding = finding_for(three, 31)
    assert finding, "Three or more reduced relatives should be flagged"
    assert_equal 3, finding[:match_count]
  end

  def test_reduced_object_relatives_ignore_conjunction_before_pronoun
    text = "The team and you decide. The cat and we want food. A dog or they need water. The plan and I need time."
    assert_nil finding_for(text, 31)
  end

  def test_denominal_verbs_detected
    finding = finding_for("Please footnote it and roadmap this for next quarter.", 32)
    assert finding, "Should detect ad hoc denominal verbs"
    assert_equal 2, finding[:match_count]
  end

  def test_denominal_verbs_ignore_nouns
    assert_nil finding_for("Add a footnote to the calendar and check the roadmap.", 32)
  end

  def test_new_signals_leave_plain_human_text_alone
    text = "Called the plumber this morning. He can come Thursday between 8 and noon. The leak is under the kitchen sink and it drips about once a second."
    assert_operator Humanizer.score(text), :<=, 10
    [ 30, 31, 32 ].each { |id| assert_nil finding_for(text, id) }
  end

  def test_invisible_unicode_detected
    text = "Hello\u200Bworld this is\u200C a test\u200D with hidden chars."
    result = Humanizer.analyze(text)
    unicode_finding = result.findings.find { |f| f[:pattern_id] == 29 }
    assert unicode_finding, "Should detect invisible unicode"
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
    assert_equal 32, registry.all.length
    assert registry.find(7), "Should find pattern 7"
    assert registry.by_category(:language).length > 0
    assert registry.categories.include?(:language)
  end
end
