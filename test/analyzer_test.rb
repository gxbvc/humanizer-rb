# frozen_string_literal: true

require "test_helper"

class AnalyzerTest < Minitest::Test
  def test_empty_text_returns_zero
    result = Humanizer.analyze("")
    assert_equal 0, result.score
  end

  def test_nil_text_returns_zero
    result = Humanizer.analyze(nil)
    assert_equal 0, result.score
  end

  def test_score_returns_integer
    score = Humanizer.score("Hello world, this is a test.")
    assert score.is_a?(Integer)
    assert score >= 0 && score <= 100
  end

  def test_analyze_returns_result_struct
    result = Humanizer.analyze("Some text to analyze here.")
    assert result.respond_to?(:score)
    assert result.respond_to?(:pattern_score)
    assert result.respond_to?(:uniformity_score)
    assert result.respond_to?(:findings)
    assert result.respond_to?(:categories)
    assert result.respond_to?(:summary)
    assert result.respond_to?(:stats)
  end

  def test_verbose_shows_all_matches
    text = "We leverage innovation. We leverage synergy. We leverage transformation. We leverage excellence. We leverage greatness. We leverage potential."
    brief = Humanizer.analyze(text, verbose: false)
    verbose = Humanizer.analyze(text, verbose: true)

    # Verbose should show more matches in at least one finding
    brief_max = brief.findings.map { |f| f[:matches].length }.max || 0
    verbose_max = verbose.findings.map { |f| f[:matches].length }.max || 0
    assert verbose_max >= brief_max
  end

  def test_patterns_to_check_filters
    text = "We must delve into this comprehensive tapestry. Great question! I hope this helps!"
    full = Humanizer.analyze(text)
    filtered = Humanizer.analyze(text, patterns_to_check: [7])

    assert full.findings.length >= filtered.findings.length
    filtered.findings.each { |f| assert_equal 7, f[:pattern_id] }
  end

  def test_format_report
    result = Humanizer.analyze("We must delve into this comprehensive tapestry of innovation.")
    report = Humanizer::Analyzer.format_report(result)
    assert report.include?("AI WRITING PATTERN ANALYSIS")
    assert report.include?("Score:")
  end

  def test_format_markdown
    result = Humanizer.analyze("We must delve into this comprehensive tapestry of innovation.")
    md = Humanizer::Analyzer.format_markdown(result)
    assert md.include?("# AI writing pattern analysis")
    assert md.include?("**Score:")
  end

  def test_format_json
    result = Humanizer.analyze("Hello world.")
    json = Humanizer::Analyzer.format_json(result)
    parsed = JSON.parse(json)
    assert parsed.key?("score")
  end
end
