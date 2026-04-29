# frozen_string_literal: true

module Humanizer
  module Analyzer
    CATEGORY_LABELS = {
      content: "Content patterns",
      language: "Language & grammar",
      style: "Style patterns",
      communication: "Communication artifacts",
      filler: "Filler & hedging",
    }.freeze

    Result = Struct.new(
      :score, :pattern_score, :uniformity_score, :total_matches,
      :word_count, :stats, :categories, :findings, :summary,
      keyword_init: true
    )

    module_function

    def analyze(text, verbose: false, patterns_to_check: nil, include_stats: true)
      return empty_result if text.nil? || !text.is_a?(String)

      trimmed = text.strip
      return empty_result if trimmed.empty?

      words = TextUtils.word_count(trimmed)

      # Compute text statistics
      stats = include_stats ? Stats.compute(trimmed) : nil
      uniformity = if stats && stats.word_count >= 20 && stats.sentence_count >= 3
                     Stats.uniformity_score(stats)
                   else
                     0
                   end

      # Run pattern detectors
      findings = []
      category_scores = {}
      CATEGORY_LABELS.each_key { |cat| category_scores[cat] = { matches: 0, weighted_score: 0, patterns: [] } }

      active_patterns = if patterns_to_check
                          Patterns::PATTERNS.select { |p| patterns_to_check.include?(p.id) }
                        else
                          Patterns::PATTERNS
                        end

      active_patterns.each do |pattern|
        matches = pattern.detector.call(trimmed)
        next if matches.empty?

        finding = {
          pattern_id: pattern.id,
          pattern_name: pattern.name,
          category: pattern.category,
          description: pattern.description,
          weight: pattern.weight,
          match_count: matches.length,
          matches: verbose ? matches : matches.first(5),
          truncated: !verbose && matches.length > 5,
        }

        findings << finding
        cat = pattern.category
        category_scores[cat][:matches] += matches.length
        category_scores[cat][:weighted_score] += matches.length * pattern.weight
        category_scores[cat][:patterns] << pattern.name
      end

      # Calculate composite score
      pattern_score = calculate_pattern_score(findings, words)
      composite_score = calculate_composite_score(pattern_score, uniformity, findings)

      # Build category summary
      categories = {}
      CATEGORY_LABELS.each do |cat, label|
        data = category_scores[cat]
        categories[cat] = {
          label: label,
          matches: data[:matches],
          weighted_score: data[:weighted_score],
          patterns_detected: data[:patterns],
        }
      end

      total_matches = findings.sum { |f| f[:match_count] }

      Result.new(
        score: composite_score,
        pattern_score: pattern_score,
        uniformity_score: uniformity,
        total_matches: total_matches,
        word_count: words,
        stats: stats,
        categories: categories,
        findings: findings,
        summary: build_summary(composite_score, total_matches, findings, words, stats),
      )
    end

    def score(text)
      analyze(text).score
    end

    # ── Scoring ──────────────────────────────────────────

    def calculate_pattern_score(findings, words)
      return 0 if words == 0 || findings.empty?

      weighted_total = findings.sum { |f| f[:match_count] * f[:weight] }

      # Density: weighted hits per 100 words (log scale)
      density = (weighted_total.to_f / words) * 100
      density_score = [Math.log2(density + 1) * 13, 65].min

      # Breadth: unique pattern types (max 20)
      breadth_bonus = [findings.length * 2, 20].min

      # Category diversity (max 15)
      categories_hit = findings.map { |f| f[:category] }.uniq.length
      category_bonus = [categories_hit * 3, 15].min

      [((density_score + breadth_bonus + category_bonus).round), 100].min
    end

    def calculate_composite_score(pattern_score, uniformity_score, findings)
      return 0 if pattern_score == 0 && uniformity_score == 0

      # If no patterns detected, uniformity alone isn't enough to accuse
      if findings.empty?
        return [(uniformity_score * 0.15).round, 15].min
      end

      # Weighted blend: patterns dominate, stats supplement
      blended = pattern_score * 0.7 + uniformity_score * 0.3
      [blended.round, 100].min
    end

    def build_summary(final_score, total_matches, findings, words, stats)
      if total_matches == 0 && final_score < 10
        return "No significant AI writing patterns detected. The text looks human-written."
      end

      level = if final_score >= 70 then "heavily AI-generated"
              elsif final_score >= 45 then "moderately AI-influenced"
              elsif final_score >= 20 then "lightly AI-touched"
              else "mostly human-sounding"
              end

      top_patterns = findings
        .sort_by { |f| -(f[:match_count] * f[:weight]) }
        .first(3)
        .map { |f| f[:pattern_name] }

      summary = "Score: #{final_score}/100 (#{level}). Found #{total_matches} matches across #{findings.length} pattern types in #{words} words."

      if top_patterns.any?
        summary += " Top issues: #{top_patterns.join(', ')}."
      end

      if stats && stats.sentence_count > 3
        if stats.burstiness < 0.25
          summary += " Sentence rhythm is very uniform (low burstiness) — typical of AI text."
        end
        if stats.type_token_ratio < 0.4 && words > 100
          summary += " Vocabulary diversity is low."
        end
      end

      summary
    end

    def empty_result
      Result.new(
        score: 0, pattern_score: 0, uniformity_score: 0,
        total_matches: 0, word_count: 0, stats: nil,
        categories: {}, findings: [], summary: "No text provided.",
      )
    end

    # ── Formatting ───────────────────────────────────────

    def format_report(result)
      lines = []
      lines << ""
      lines << "\u2554#{'═' * 50}\u2557"
      lines << "\u2551          AI WRITING PATTERN ANALYSIS             \u2551"
      lines << "\u255A#{'═' * 50}\u255D"
      lines << ""

      filled = (result.score / 5.0).round
      bar = "\u2588" * filled + "\u2591" * (20 - filled)
      lines << "  Score: #{result.score}/100  [#{bar}]"
      lines << "  Words: #{result.word_count}  |  Matches: #{result.total_matches}  |  Pattern: #{result.pattern_score}  |  Uniformity: #{result.uniformity_score}"
      lines << ""
      lines << "  #{result.summary}"
      lines << ""

      if result.stats
        s = result.stats
        lines << "── Text Statistics ─────────────────────────────────"
        lines << "  Sentences: #{s.sentence_count}  |  Paragraphs: #{s.paragraph_count}"
        lines << "  Avg sentence length: #{s.avg_sentence_length} words (σ #{s.sentence_length_std_dev})"
        lines << "  Burstiness: #{s.burstiness}"
        lines << "  Vocabulary diversity (TTR): #{s.type_token_ratio}"
        lines << "  Function word ratio: #{s.function_word_ratio}"
        lines << "  Trigram repetition: #{s.trigram_repetition}"
        lines << "  Readability (FK grade): #{s.flesch_kincaid}"
        lines << ""
      end

      lines << "── Categories ──────────────────────────────────────"
      result.categories.each do |_, data|
        if data[:matches] > 0
          lines << "  #{data[:label]}: #{data[:matches]} matches (#{data[:patterns_detected].join(', ')})"
        end
      end
      lines << ""

      if result.findings.any?
        lines << "── Findings ────────────────────────────────────────"
        result.findings.each do |finding|
          lines << ""
          lines << "  [#{finding[:pattern_id]}] #{finding[:pattern_name]} (×#{finding[:match_count]}, weight: #{finding[:weight]})"
          lines << "      #{finding[:description]}"
          finding[:matches].each do |match|
            loc = match[:line] ? "L#{match[:line]}:#{match[:column] || ''}" : ""
            preview = match[:match].is_a?(String) ? match[:match][0, 80] : ""
            preview += "..." if match[:match].is_a?(String) && match[:match].length > 80
            conf = match[:confidence] ? " [#{match[:confidence]}]" : ""
            lines << "      #{loc}: \"#{preview}\"#{conf}"
            lines << "            → #{match[:suggestion]}" if match[:suggestion]
          end
          if finding[:truncated]
            lines << "      ... and #{finding[:match_count] - finding[:matches].length} more"
          end
        end
      end

      lines << ""
      lines << "════════════════════════════════════════════════════"
      lines.join("\n")
    end

    def format_markdown(result)
      lines = []
      lines << "# AI writing pattern analysis"
      lines << ""

      level = if result.score >= 70 then "Heavily AI-generated"
              elsif result.score >= 45 then "Moderately AI-influenced"
              elsif result.score >= 20 then "Lightly AI-touched"
              else "Mostly human-sounding"
              end

      lines << "**Score: #{result.score}/100** — #{level}"
      lines << ""
      lines << "Words: #{result.word_count} | Matches: #{result.total_matches} | Pattern score: #{result.pattern_score} | Uniformity score: #{result.uniformity_score}"
      lines << ""
      lines << result.summary
      lines << ""

      if result.stats
        s = result.stats
        lines << "## Text statistics"
        lines << ""
        lines << "| Metric | Value | Assessment |"
        lines << "|--------|-------|------------|"
        lines << "| Avg sentence length | #{s.avg_sentence_length} words | #{s.avg_sentence_length > 25 ? 'Long' : s.avg_sentence_length < 12 ? 'Short' : 'Normal'} |"
        lines << "| Sentence variation | σ #{s.sentence_length_std_dev} | #{s.sentence_length_std_dev > 8 ? 'High (human-like)' : s.sentence_length_std_dev < 4 ? 'Low (AI-like)' : 'Moderate'} |"
        lines << "| Burstiness | #{s.burstiness} | #{burstiness_label(s.burstiness)} |"
        lines << "| Vocabulary diversity | #{s.type_token_ratio} | #{ttr_label(s.type_token_ratio, s.word_count)} |"
        lines << "| Trigram repetition | #{s.trigram_repetition} | #{s.trigram_repetition > 0.1 ? 'High (AI-like)' : 'Normal'} |"
        lines << "| Readability | FK grade #{s.flesch_kincaid} | #{s.flesch_kincaid > 12 ? 'Academic' : s.flesch_kincaid > 8 ? 'Standard' : 'Easy'} |"
        lines << ""
      end

      if result.findings.any?
        lines << "## Findings"
        lines << ""
        result.findings.each do |finding|
          lines << "### #{finding[:pattern_id]}. #{finding[:pattern_name]} (×#{finding[:match_count]})"
          lines << "*#{finding[:description]}*"
          lines << ""
          finding[:matches].each do |match|
            loc = match[:line] ? "Line #{match[:line]}" : ""
            preview = match[:match].is_a?(String) ? match[:match][0, 80] : ""
            lines << "- #{loc}: `#{preview}`"
            lines << "  - #{match[:suggestion]}" if match[:suggestion]
          end
          lines << ""
        end
      end

      lines.join("\n")
    end

    def format_json(result)
      require "json"
      JSON.pretty_generate(result.to_h)
    end

    def burstiness_label(b)
      if b >= 0.7 then "(high — human-like)"
      elsif b >= 0.45 then "(moderate)"
      elsif b >= 0.25 then "(low — somewhat uniform)"
      else "(very low — AI-like uniformity)"
      end
    end

    def ttr_label(ttr, wc)
      if wc < 100 then "(too short to assess)"
      elsif ttr >= 0.6 then "(high — diverse vocabulary)"
      elsif ttr >= 0.45 then "(moderate)"
      else "(low — repetitive vocabulary)"
      end
    end
  end
end
