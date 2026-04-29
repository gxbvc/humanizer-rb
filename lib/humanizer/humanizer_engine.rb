# frozen_string_literal: true

module Humanizer
  module HumanizerEngine
    module_function

    # Apply safe, mechanical fixes that don't require judgment.
    def auto_fix(text)
      result = text.dup
      fixes = []

      # Curly quotes → straight quotes
      if result.match?(/[\u201C\u201D]/)
        result.gsub!(/[\u201C\u201D]/, '"')
        fixes << "Replaced curly double quotes with straight quotes"
      end
      if result.match?(/[\u2018\u2019]/)
        result.gsub!(/[\u2018\u2019]/, "'")
        fixes << "Replaced curly single quotes with straight quotes"
      end

      # Filler phrase replacements (unambiguous)
      safe_fills = [
        { from: /\bin order to\b/i, to: "to", label: '"in order to" → "to"' },
        { from: /\bdue to the fact that\b/i, to: "because", label: '"due to the fact that" → "because"' },
        { from: /\bat this point in time\b/i, to: "now", label: '"at this point in time" → "now"' },
        { from: /\bin the event that\b/i, to: "if", label: '"in the event that" → "if"' },
        { from: /\bhas the ability to\b/i, to: "can", label: '"has the ability to" → "can"' },
        { from: /\bfor the purpose of\b/i, to: "to", label: '"for the purpose of" → "to"' },
        { from: /\bfirst and foremost\b/i, to: "first", label: '"first and foremost" → "first"' },
        { from: /\bin light of the fact that\b/i, to: "because", label: '"in light of the fact that" → "because"' },
        { from: /\bin the realm of\b/i, to: "in", label: '"in the realm of" → "in"' },
        { from: /\butilize\b/i, to: "use", label: '"utilize" → "use"' },
        { from: /\butilizing\b/i, to: "using", label: '"utilizing" → "using"' },
        { from: /\butilization\b/i, to: "use", label: '"utilization" → "use"' },
      ]

      safe_fills.each do |fill|
        if result.match?(fill[:from])
          result.gsub!(fill[:from], fill[:to])
          fixes << fill[:label]
        end
      end

      # Chatbot artifact removal (start of text)
      chatbot_start = [
        /^(?:Here is|Here's) (?:a |an |the )?(?:comprehensive |brief |quick )?(?:overview|summary|breakdown|list|guide|explanation|look)[^.]*\.\s*/i,
        /^(?:Of course|Certainly|Absolutely|Sure)!\s*/i,
        /^(?:Great|Excellent|Good|Wonderful|Fantastic) question!\s*/i,
        /^(?:That's|That is) a (?:great|excellent|good|wonderful|fantastic) (?:question|point)!\s*/i,
      ]
      chatbot_start.each do |regex|
        if result.match?(regex)
          result.sub!(regex, "")
          fixes << "Removed chatbot opening artifact"
        end
      end

      # Chatbot artifact removal (end of text)
      chatbot_end = [
        /\s*(?:I hope this helps|Let me know if you(?:'d| would) like|Feel free to|Don't hesitate to|Is there anything else)[^.]*[.!]\s*$/i,
        /\s*Happy to help[.!]?\s*$/i,
      ]
      chatbot_end.each do |regex|
        if result.match?(regex)
          result.sub!(regex, "")
          fixes << "Removed chatbot closing artifact"
        end
      end

      { text: result.strip, fixes: fixes }
    end

    # Generate humanization suggestions
    def humanize(text, autofix: false, verbose: false, include_stats: true)
      analysis = Analyzer.analyze(text, verbose: true, include_stats: include_stats)

      critical = []
      important = []
      minor = []

      analysis.findings.each do |finding|
        suggestions = finding[:matches].map { |m|
          {
            pattern: finding[:pattern_name],
            pattern_id: finding[:pattern_id],
            category: finding[:category],
            weight: finding[:weight],
            text: m[:match],
            line: m[:line],
            column: m[:column],
            suggestion: m[:suggestion],
            confidence: m[:confidence] || "high",
          }
        }

        if finding[:weight] >= 4
          critical.concat(suggestions)
        elsif finding[:weight] >= 2
          important.concat(suggestions)
        else
          minor.concat(suggestions)
        end
      end

      fix_result = autofix ? auto_fix(text) : nil

      guidance = build_guidance(analysis)
      style_tips = include_stats && analysis.stats ? build_style_tips(analysis.stats) : []

      {
        score: analysis.score,
        pattern_score: analysis.pattern_score,
        uniformity_score: analysis.uniformity_score,
        word_count: analysis.word_count,
        total_issues: analysis.total_matches,
        stats: analysis.stats,
        critical: critical,
        important: important,
        minor: minor,
        autofix: fix_result,
        guidance: guidance,
        style_tips: style_tips,
      }
    end

    def build_guidance(analysis)
      tips = []
      ids = analysis.findings.map { |f| f[:pattern_id] }.to_set

      tips << "Replace inflated/promotional language with concrete facts. What specifically happened? Give dates, numbers, names." if ids.include?(1) || ids.include?(4)
      tips << "Cut trailing -ing phrases. If the point matters enough to mention, give it its own sentence." if ids.include?(3)
      tips << "Name your sources. \"Experts say\" means nothing — who said it, when, and where?" if ids.include?(5)
      tips << "Replace formulaic \"despite challenges\" sections with specific problems and concrete outcomes." if ids.include?(6)
      tips << "Swap AI vocabulary for plainer words. \"Delve\" → \"look at\". \"Tapestry\" → (be specific). \"Showcase\" → \"show\"." if ids.include?(7)
      tips << "Use \"is\" and \"has\" freely. \"Serves as\" and \"boasts\" are needlessly fancy." if ids.include?(8)
      tips << "Drop \"not just X, it's Y\" frames. Just say what the thing is." if ids.include?(9)
      tips << "Break up triads. You don't always need three of everything." if ids.include?(10)
      tips << "Ease up on em dashes. Use commas, periods, or parentheses for variety." if ids.include?(13)
      tips << "Strip mechanical bold formatting and inline-header lists. Let prose do the work." if ids.include?(14) || ids.include?(15)
      tips << "Remove emojis from professional text. They signal chatbot output." if ids.include?(17)
      tips << "Remove chatbot filler (\"I hope this helps!\", \"Great question!\"). Just deliver the content." if ids.include?(19) || ids.include?(21)
      tips << "Delete knowledge-cutoff disclaimers. Either research it or leave it out." if ids.include?(20)
      tips << "Trim filler and hedging. \"In order to\" → \"to\". One qualifier per claim is enough." if ids.include?(22) || ids.include?(23)
      tips << "Cut generic conclusions. End with a specific fact instead of \"the future looks bright\"." if ids.include?(24)

      if analysis.score >= 50
        tips << "Consider rewriting from scratch. When AI patterns are this dense, patching individual phrases isn't enough — the structure itself needs rethinking."
      end

      tips
    end

    def build_style_tips(stats)
      tips = []

      if stats.burstiness < 0.25 && stats.sentence_count > 4
        tips << { metric: "burstiness", value: stats.burstiness,
                  tip: "Sentence rhythm is very uniform. Mix short punchy sentences (3-8 words) with longer flowing ones (20+). Fragments work too. Like this." }
      end

      if stats.sentence_length_variation < 0.3 && stats.sentence_count > 4
        tips << { metric: "sentence_length_variation", value: stats.sentence_length_variation,
                  tip: "Sentences are all roughly #{stats.avg_sentence_length.round} words. Vary your rhythm — alternate between short and long." }
      end

      if stats.avg_sentence_length > 28
        tips << { metric: "avg_sentence_length", value: stats.avg_sentence_length,
                  tip: "Average sentence is quite long. Break some into shorter ones. Not every thought needs a subordinate clause." }
      end

      if stats.type_token_ratio < 0.4 && stats.word_count > 100
        tips << { metric: "type_token_ratio", value: stats.type_token_ratio,
                  tip: "Vocabulary is repetitive. Try using more varied word choices — but don't synonym-cycle (that's also an AI tell)." }
      end

      if stats.trigram_repetition > 0.1 && stats.word_count > 100
        tips << { metric: "trigram_repetition", value: stats.trigram_repetition,
                  tip: "Repeated 3-word phrases detected. Vary your sentence structures." }
      end

      if tips.length >= 2
        tips << { metric: "general", value: nil,
                  tip: "Try the read-aloud test: read the text out loud. If it sounds weird or robotic, rewrite those parts until they sound like something you'd actually say." }
        tips << { metric: "general", value: nil,
                  tip: "Add first-person perspective where it fits: \"I found\", \"We noticed\", \"In my experience\". Real humans write from a point of view." }
      end

      tips
    end
  end
end
