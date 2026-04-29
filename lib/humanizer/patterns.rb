# frozen_string_literal: true

module Humanizer
  module Patterns
    Pattern = Struct.new(:id, :name, :category, :description, :weight, :detector, keyword_init: true)

    # ── Phrase Lists ─────────────────────────────────────

    SIGNIFICANCE_PHRASES = [
      /marking a pivotal/i, /pivotal moment/i, /pivotal role/i,
      /key role/i, /crucial role/i, /vital role/i, /significant role/i,
      /is a testament/i, /stands as a testament/i, /serves as a testament/i,
      /serves as a reminder/i, /reflects broader/i, /broader trends/i,
      /broader movement/i, /evolving landscape/i, /evolving world/i,
      /setting the stage for/i, /marking a shift/i, /key turning point/i,
      /indelible mark/i, /deeply rooted/i, /focal point/i,
      /symbolizing its ongoing/i, /enduring legacy/i, /lasting impact/i,
      /contributing to the/i, /underscores the importance/i,
      /highlights the significance/i, /represents a shift/i,
      /shaping the future/i, /the evolution of/i, /rich tapestry/i,
      /rich heritage/i, /stands as a beacon/i, /marks a milestone/i,
      /paving the way/i, /charting a course/i,
    ].freeze

    PROMOTIONAL_WORDS = [
      /\bnestled\b/i, /\bin the heart of\b/i, /\bbreathtaking\b/i,
      /\bmust-visit\b/i, /\bstunning\b/i, /\brenowned\b/i,
      /\bnatural beauty\b/i, /\brich cultural heritage\b/i,
      /\brich history\b/i, /\bcommitment to\b/i, /\bexemplifies\b/i,
      /\bworld-class\b/i, /\bstate-of-the-art\b/i, /\bgame-changing\b/i,
      /\bgame changer\b/i, /\bunparalleled\b/i, /\bprofound\b/i,
      /\bbest-in-class\b/i, /\btrailblazing\b/i, /\bvisionary\b/i,
      /\bcutting-edge\b/i, /\bworldwide recognition\b/i,
    ].freeze

    VAGUE_ATTRIBUTION_PHRASES = [
      /\bexperts (?:believe|argue|say|suggest|note|agree|contend|have noted)\b/i,
      /\bindustry (?:reports|observers|experts|analysts|leaders|insiders)\b/i,
      /\bobservers have (?:cited|noted|pointed out)\b/i,
      /\bsome critics argue\b/i,
      /\bsome experts (?:say|believe|suggest)\b/i,
      /\bseveral sources\b/i, /\baccording to reports\b/i,
      /\bwidely (?:regarded|considered|recognized|acknowledged)\b/i,
      /\bit is widely (?:known|believed|accepted)\b/i,
      /\bmany (?:experts|scholars|researchers|analysts) (?:believe|argue|suggest)\b/i,
      /\bstudies (?:show|suggest|indicate|have shown)\b/i,
      /\bresearch (?:shows|suggests|indicates|has shown)\b/i,
      /\bsources close to\b/i, /\bpeople familiar with\b/i,
    ].freeze

    CHALLENGES_PHRASES = [
      /despite (?:its|these|the|their) (?:challenges|setbacks|obstacles|difficulties|limitations)/i,
      /faces (?:several|many|numerous|various) challenges/i,
      /continues to thrive/i, /continues to grow/i,
      /future (?:outlook|prospects) (?:remain|look|appear)/i,
      /challenges and (?:future|legacy|opportunities)/i,
      /despite these (?:challenges|hurdles|obstacles)/i,
      /overcoming (?:obstacles|challenges|adversity)/i,
      /weather(?:ing|ed) the storm/i,
    ].freeze

    COPULA_AVOIDANCE = [
      /\bserves as(?: a)?\b/i, /\bstands as(?: a)?\b/i,
      /\bmarks a\b/i, /\brepresents a\b/i,
      /\bboasts (?:a|an|over|more)\b/i, /\bfeatures (?:a|an|over|more)\b/i,
      /\boffers (?:a|an)\b/i, /\bfunctions as\b/i,
      /\bacts as(?: a)?\b/i, /\boperates as(?: a)?\b/i,
    ].freeze

    # ── Helper Methods ───────────────────────────────────

    module_function

    def scan_word_list(text, word_list, suggestion_prefix, confidence: "high")
      results = []
      word_list.each do |word|
        regex = TextUtils.word_regex(word)
        matches = TextUtils.find_matches(
          text, regex,
          "#{suggestion_prefix}: \"#{word}\". Use a simpler, more specific alternative.",
          confidence: confidence
        )
        results.concat(matches)
      end
      results
    end

    def scan_phrases(text, phrases, tier_filter: nil)
      results = []
      phrases.each do |phrase|
        next if tier_filter && phrase[:tier] != tier_filter

        fix = phrase[:fix]
        suggestion = fix.start_with?("(") ? fix : "Replace with: #{fix}"
        confidence = case phrase[:tier]
                     when 1 then "high"
                     when 2 then "medium"
                     else "low"
                     end

        matches = TextUtils.find_matches(text, phrase[:pattern], suggestion, confidence: confidence)
        results.concat(matches)
      end
      results
    end

    # ── Pattern Definitions ──────────────────────────────

    PATTERNS = [
      # ── CONTENT PATTERNS (1-6) ────────────────────────

      Pattern.new(
        id: 1, name: "Significance inflation", category: :content, weight: 4,
        description: "Inflated claims about significance, legacy, or broader trends. LLMs puff up importance of mundane things.",
        detector: ->(text) {
          SIGNIFICANCE_PHRASES.flat_map { |re|
            TextUtils.find_matches(text, re, "Remove inflated significance claim. State concrete facts instead.", confidence: "high")
          }
        }
      ),

      Pattern.new(
        id: 2, name: "Notability name-dropping", category: :content, weight: 3,
        description: "Listing media outlets or sources to claim notability without providing context or specific claims.",
        detector: ->(text) {
          media_list = /\b(?:cited|featured|covered|mentioned|reported|published|recognized|highlighted) (?:in|by) .{0,20}(?:The New York Times|BBC|CNN|The Washington Post|The Guardian|Wired|Forbes|Reuters|Bloomberg|Financial Times|The Verge|TechCrunch|The Hindu|Al Jazeera|Time|Newsweek|The Economist|Nature|Science).{0,100}(?:,\s*(?:and\s+)?(?:The New York Times|BBC|CNN|The Washington Post|The Guardian|Wired|Forbes|Reuters|Bloomberg|Financial Times|The Verge|TechCrunch|The Hindu|Al Jazeera|Time|Newsweek|The Economist|Nature|Science))+/i
          results = TextUtils.find_matches(text, media_list, "Instead of listing outlets, cite one specific claim from one source.", confidence: "high")
          results.concat TextUtils.find_matches(text, /\bactive social media presence\b/i, "Remove — not meaningful without specific context.", confidence: "high")
          results.concat TextUtils.find_matches(text, /\bwritten by a leading expert\b/i, "Name the expert and their specific credential.", confidence: "medium")
          results.concat TextUtils.find_matches(text, /\bhas been (?:featured|recognized|acknowledged) (?:by|in)\b/i, "Cite the specific feature with a concrete claim.", confidence: "medium")
          results
        }
      ),

      Pattern.new(
        id: 3, name: "Superficial -ing analyses", category: :content, weight: 4,
        description: 'Tacking "-ing" participial phrases onto sentences to fake depth.',
        detector: ->(text) {
          ing_phrases = /,\s*(?:highlighting|underscoring|emphasizing|ensuring|reflecting|symbolizing|contributing to|cultivating|fostering|encompassing|showcasing|demonstrating|illustrating|representing|signaling|indicating|solidifying|reinforcing|cementing|underscoring|bolstering|reaffirming|illuminating|epitomizing)\b[^.]{5,}/i
          TextUtils.find_matches(text, ing_phrases, "Remove trailing -ing phrase. If the point matters, give it its own sentence with specifics.", confidence: "high")
        }
      ),

      Pattern.new(
        id: 4, name: "Promotional language", category: :content, weight: 3,
        description: "Ad-copy language that sounds like a tourism brochure or press release.",
        detector: ->(text) {
          PROMOTIONAL_WORDS.flat_map { |re|
            TextUtils.find_matches(text, re, "Replace promotional language with neutral, factual description.", confidence: "high")
          }
        }
      ),

      Pattern.new(
        id: 5, name: "Vague attributions", category: :content, weight: 4,
        description: "Attributing claims to unnamed experts, industry reports, or vague authorities.",
        detector: ->(text) {
          VAGUE_ATTRIBUTION_PHRASES.flat_map { |re|
            TextUtils.find_matches(text, re, "Name the specific source, study, or person. If you can't, remove the claim.", confidence: "high")
          }
        }
      ),

      Pattern.new(
        id: 6, name: "Formulaic challenges", category: :content, weight: 3,
        description: 'Boilerplate "Despite challenges... continues to thrive" sections.',
        detector: ->(text) {
          CHALLENGES_PHRASES.flat_map { |re|
            TextUtils.find_matches(text, re, "Replace with specific challenges and concrete outcomes.", confidence: "high")
          }
        }
      ),

      # ── LANGUAGE PATTERNS (7-12) ──────────────────────

      Pattern.new(
        id: 7, name: "AI vocabulary", category: :language, weight: 5,
        description: "Words and phrases that appear far more frequently in AI-generated text. 500+ words tracked across 3 tiers.",
        detector: ->(text) {
          results = []
          words = TextUtils.word_count(text)

          # Tier 1: always flag
          all_tier1 = Vocabulary::TIER_1 + Vocabulary::TIER_1_PHRASES
          results.concat Patterns.scan_word_list(text, all_tier1, "Tier 1 AI word", confidence: "high")

          # Tier 2: flag if 2+ tier-2 words appear
          tier2_matches = Patterns.scan_word_list(text, Vocabulary::TIER_2, "Tier 2 AI word", confidence: "medium")
          results.concat(tier2_matches) if tier2_matches.length >= 2

          # Tier 3: flag only at high density (>3% of words are tier-3)
          if words > 50
            tier3_count = Vocabulary::TIER_3.sum { |word|
              TextUtils.count_matches(text, TextUtils.word_regex(word))
            }
            density = tier3_count.to_f / words
            if density > 0.03
              results.concat Patterns.scan_word_list(text, Vocabulary::TIER_3, "Tier 3 AI word (high density)", confidence: "low")
            end
          end

          # AI phrases (non-remove, non-simple-replacement)
          filtered = Vocabulary::AI_PHRASES.select { |p|
            p[:fix] &&
              !p[:fix].start_with?("(remove") &&
              !%w[to because now if can first finally].include?(p[:fix])
          }
          results.concat Patterns.scan_phrases(text, filtered)

          results
        }
      ),

      Pattern.new(
        id: 8, name: "Copula avoidance", category: :language, weight: 3,
        description: 'Using "serves as", "functions as", "boasts" instead of simple "is", "has", "are".',
        detector: ->(text) {
          COPULA_AVOIDANCE.flat_map { |re|
            TextUtils.find_matches(text, re, 'Use simple "is", "are", or "has" instead.', confidence: "high")
          }
        }
      ),

      Pattern.new(
        id: 9, name: "Negative parallelisms", category: :language, weight: 3,
        description: '"It\'s not just X, it\'s Y" or "That\'s not X, it\'s Y" or "Not only X but Y" constructions — overused by LLMs.',
        detector: ->(text) {
          neg_parallel = /\b(?:it'?s|this is) not (?:just|merely|only|simply) .{3,60}(?:,|;|\u2014)\s*(?:it'?s|this is|but)\b/i
          not_only = /\bnot only .{3,60} but (?:also )?\b/i
          # Plain "That's not X, it's Y" reframe without just/merely/only/simply
          neg_reframe = /\b(?:that'?s|it'?s|this is(?:n'?t)) not .{3,60}(?:,|;|\u2014)\s*(?:it'?s|that'?s|this is)\b/i
          results = TextUtils.find_matches(text, neg_parallel, 'Rewrite directly. State what the thing IS, not what it "isn\'t just".', confidence: "high")
          results.concat TextUtils.find_matches(text, not_only, 'Simplify. Remove the "not only...but also" frame.', confidence: "medium")
          results.concat TextUtils.find_matches(text, neg_reframe, 'AI reframe pattern: "That\'s not X, it\'s Y." Just say what it is directly.', confidence: "medium")
          results
        }
      ),

      Pattern.new(
        id: 10, name: "Rule of three", category: :language, weight: 2,
        description: 'Forcing ideas into groups of three. LLMs love triads that sound "comprehensive".',
        detector: ->(text) {
          # Abstract noun triads
          buzzy_triad = /\b(\w+tion|\w+ity|\w+ment|\w+ness|\w+ance|\w+ence),\s+(\w+tion|\w+ity|\w+ment|\w+ness|\w+ance|\w+ence),\s+and\s+(\w+tion|\w+ity|\w+ment|\w+ness|\w+ance|\w+ence)\b/i
          results = TextUtils.find_matches(text, buzzy_triad, "Rule of three with abstract nouns. Pick the one or two that actually matter.", confidence: "medium")

          buzz_adj = %w[seamless intuitive powerful innovative dynamic robust comprehensive cutting-edge scalable agile efficient effective engaging impactful meaningful transformative sustainable resilient inclusive accessible]
          adj_pattern = buzz_adj.join("|")
          adj_triad = /\b(#{adj_pattern}),\s+(#{adj_pattern}),\s+and\s+(#{adj_pattern})\b/i
          results.concat TextUtils.find_matches(text, adj_triad, "Buzzy adjective triad. Pick one and make it specific.", confidence: "medium")

          results
        }
      ),

      Pattern.new(
        id: 11, name: "Synonym cycling", category: :language, weight: 2,
        description: "Referring to the same thing by different names in consecutive sentences to avoid repetition.",
        detector: ->(text) {
          synonym_sets = [
            %w[protagonist main\ character central\ figure hero lead\ character lead],
            %w[company firm organization enterprise corporation establishment entity],
            %w[city metropolis urban\ center municipality locale township],
            %w[building structure edifice facility complex establishment],
            %w[tool instrument mechanism apparatus device utility],
            %w[country nation state republic sovereign\ state],
            %w[problem challenge issue obstacle hurdle difficulty],
            %w[solution approach methodology framework strategy paradigm],
          ]

          results = []
          sentences = text.split(/[.!?]+/).select { |s| s.strip.length > 0 }

          synonym_sets.each do |synonyms|
            (0...sentences.length - 1).each do |i|
              found = []
              (i...[i + 4, sentences.length].min).each do |j|
                lower = sentences[j].downcase
                synonyms.each do |syn|
                  if lower.include?(syn) && !found.include?(syn)
                    found << syn
                  end
                end
              end
              if found.length >= 3
                idx = text.index(sentences[i]) || 0
                line_num = text[0...idx].count("\n") + 1
                results << {
                  match: "Synonym cycling: #{found.join(' → ')}",
                  index: idx,
                  line: line_num,
                  column: 1,
                  suggestion: "Pick one term and stick with it. Found \"#{found.join('", "')}\" used as synonyms in nearby sentences.",
                  confidence: "medium",
                }
                break
              end
            end
          end
          results
        }
      ),

      Pattern.new(
        id: 12, name: "False ranges", category: :language, weight: 2,
        description: '"From X to Y" where X and Y aren\'t on a meaningful scale.',
        detector: ->(text) {
          double_range = /\bfrom .{3,40} to .{3,40},\s*from .{3,40} to .{3,40}/i
          results = TextUtils.find_matches(text, double_range, "False range — X and Y probably aren't on a meaningful scale. Just list the topics.", confidence: "high")

          abstract_range = /\bfrom (?:the )?(?:dawn|birth|inception|beginning|advent|emergence|rise|earliest) .{3,60} to (?:the )?(?:modern|current|present|contemporary|latest|cutting-edge|digital|future)/i
          results.concat TextUtils.find_matches(text, abstract_range, "Unnecessarily broad range. Be specific about what you're actually covering.", confidence: "medium")

          results
        }
      ),

      # ── STYLE PATTERNS (13-18) ────────────────────────

      Pattern.new(
        id: 13, name: "Em dash overuse", category: :style, weight: 2,
        description: "LLMs overuse em dashes (\u2014) as a crutch for punchy writing.",
        detector: ->(text) {
          em_dashes = text.scan(/\u2014/).length
          words = TextUtils.word_count(text)
          ratio = words > 0 ? em_dashes.to_f / (words / 100.0) : 0

          if ratio > 1.0 && em_dashes >= 2
            TextUtils.find_matches(text, /\u2014/, "High em dash density (#{em_dashes} in #{words} words). Replace most with commas, periods, or parentheses.", confidence: "medium")
          else
            []
          end
        }
      ),

      Pattern.new(
        id: 14, name: "Boldface overuse", category: :style, weight: 2,
        description: "Mechanical emphasis of phrases in bold. AI uses **bold** as a highlighting crutch.",
        detector: ->(text) {
          bold_matches = text.scan(/\*\*[^*]+\*\*/)
          if bold_matches.length >= 3
            TextUtils.find_matches(text, /\*\*[^*]+\*\*/, "Excessive boldface. Remove emphasis — let the writing carry the weight.", confidence: "medium")
          else
            []
          end
        }
      ),

      Pattern.new(
        id: 15, name: "Inline-header lists", category: :style, weight: 3,
        description: "Lists where each item starts with a bolded header followed by a colon.",
        detector: ->(text) {
          inline_headers = /^[*\-]\s+\*\*[^*]+:\*\*\s/m
          matches = text.scan(inline_headers)
          if matches.length >= 2
            TextUtils.find_matches(text, inline_headers, "Inline-header list pattern. Convert to a paragraph or use a simpler list.", confidence: "high")
          else
            []
          end
        }
      ),

      Pattern.new(
        id: 16, name: "Title Case headings", category: :style, weight: 1,
        description: "Capitalizing Every Main Word In Headings. AI chatbots default to this.",
        detector: ->(text) {
          results = []
          skip_words = /^(?:I|AI|API|CLI|URL|HTML|CSS|JS|TS|NPM|NYC|USA|UK|EU|LLM|GPT|SaaS|IoT|CEO|CTO|VP|PR|HR|IT|UI|UX)\b/

          text.scan(/^(\#{1,6}\s+(.+))$/m) do
            m = Regexp.last_match
            heading = m[2].strip
            words = heading.split(/\s+/)
            if words.length >= 3
              capitalized_count = words.count { |w| w =~ /^[A-Z]/ && w !~ skip_words }
              if capitalized_count.to_f / words.length > 0.7
                idx = text.index(m[0]) || 0
                line_num = text[0...idx].count("\n") + 1
                results << {
                  match: m[0],
                  index: idx,
                  line: line_num,
                  column: 1,
                  suggestion: "Use sentence case for headings (only capitalize first word and proper nouns).",
                  confidence: "medium",
                }
              end
            end
          end
          results
        }
      ),

      Pattern.new(
        id: 17, name: "Emoji overuse", category: :style, weight: 2,
        description: "Decorating headings or bullet points with emojis in professional/technical text.",
        detector: ->(text) {
          emoji_count = TextUtils.count_matches(text, /[\u{1F300}-\u{1F9FF}\u{2600}-\u{27BF}]/u)
          if emoji_count >= 3
            TextUtils.find_matches(text, /[\u{1F300}-\u{1F9FF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}\u{2B50}]/u, "Remove emoji decoration from professional text.", confidence: "high")
          else
            []
          end
        }
      ),

      Pattern.new(
        id: 18, name: "Curly quotes", category: :style, weight: 1,
        description: "ChatGPT uses Unicode curly quotes (\u201C\u201D\u2018\u2019) instead of straight quotes.",
        detector: ->(text) {
          TextUtils.find_matches(text, /[\u201C\u201D\u2018\u2019]/, "Replace curly quotes with straight quotes.", confidence: "high")
        }
      ),

      # ── COMMUNICATION PATTERNS (19-21) ─────────────────

      Pattern.new(
        id: 19, name: "Chatbot artifacts", category: :communication, weight: 5,
        description: 'Leftover chatbot phrases: "I hope this helps!", "Let me know if...", "Here is an overview".',
        detector: ->(text) {
          filtered = Vocabulary::AI_PHRASES.select { |p|
            p[:fix] == "(remove)" || p[:fix] == "(remove — start with the content)"
          }
          Patterns.scan_phrases(text, filtered)
        }
      ),

      Pattern.new(
        id: 20, name: "Cutoff disclaimers", category: :communication, weight: 4,
        description: "AI knowledge-cutoff disclaimers left in text.",
        detector: ->(text) {
          filtered = Vocabulary::AI_PHRASES.select { |p|
            p[:fix] == "(remove)" &&
              (p[:pattern].source.include?("training") ||
               p[:pattern].source.include?("details are") ||
               p[:pattern].source.include?("available"))
          }
          Patterns.scan_phrases(text, filtered)
        }
      ),

      Pattern.new(
        id: 21, name: "Sycophantic tone", category: :communication, weight: 4,
        description: 'Overly positive, people-pleasing language: "Great question!", "You\'re absolutely right!".',
        detector: ->(text) {
          filtered = Vocabulary::AI_PHRASES.select { |p|
            p[:fix] &&
              (p[:fix].include?("(remove)") || p[:fix].include?("address the substance")) &&
              (p[:pattern].source.include?("question") ||
               p[:pattern].source.include?("point") ||
               p[:pattern].source.include?("right") ||
               p[:pattern].source.include?("observation"))
          }
          Patterns.scan_phrases(text, filtered)
        }
      ),

      # ── FILLER & HEDGING (22-24) ──────────────────────

      Pattern.new(
        id: 22, name: "Filler phrases", category: :filler, weight: 3,
        description: 'Wordy filler that can be shortened: "in order to" → "to", "due to the fact that" → "because".',
        detector: ->(text) {
          simple_fixes = %w[to because now if can first finally].push("to / for", "for / regarding", "because / since")
          filtered = Vocabulary::AI_PHRASES.select { |p|
            p[:fix] && !p[:fix].start_with?("(") && simple_fixes.include?(p[:fix])
          }
          Patterns.scan_phrases(text, filtered)
        }
      ),

      Pattern.new(
        id: 23, name: "Excessive hedging", category: :filler, weight: 3,
        description: 'Stacking qualifiers: "could potentially possibly", "might arguably perhaps".',
        detector: ->(text) {
          filtered = Vocabulary::AI_PHRASES.select { |p|
            p[:fix] &&
              (p[:fix].include?("could") || p[:fix].include?("might") ||
               p[:fix].include?("may") || p[:fix].include?("perhaps") ||
               p[:fix].include?("maybe"))
          }
          Patterns.scan_phrases(text, filtered)
        }
      ),

      Pattern.new(
        id: 24, name: "Generic conclusions", category: :filler, weight: 3,
        description: 'Vague upbeat endings: "The future looks bright", "Exciting times lie ahead".',
        detector: ->(text) {
          filtered = Vocabulary::AI_PHRASES.select { |p|
            p[:fix] &&
              (p[:fix].include?("specific fact") || p[:fix].include?("concrete") ||
               p[:fix].include?("cite evidence") || p[:fix].include?("what you do know") ||
               p[:fix].include?("what happens next"))
          }
          Patterns.scan_phrases(text, filtered)
        }
      ),

      # ── NEW PATTERNS (v2.2) ───────────────────────────

      Pattern.new(
        id: 25, name: "Reasoning chain artifacts", category: :communication, weight: 4,
        description: 'Exposed chain-of-thought reasoning: "Let me think...", "Step 1:", "Breaking this down..."',
        detector: ->(text) {
          reasoning_patterns = [
            /\blet me think(?: about this| through this| step by step)?\b/i,
            /\blet's (?:think|reason|work) (?:about|through|this out)\b/i,
            /\bbreaking (?:this|it) down\b/i,
            /\bto approach this (?:systematically|methodically|logically)\b/i,
            /\reasoning through (?:this|the problem|it)\b/i,
            /\bworking through the logic\b/i,
            /\bstep (?:[1-9]|one|two|three|four|five):/i,
            /\bfirst,? let'?s consider\b/i,
            /\bthinking about this (?:carefully|logically|systematically)\b/i,
            /\bhere'?s my (?:thought process|reasoning|thinking)\b/i,
          ]
          reasoning_patterns.flat_map { |re|
            TextUtils.find_matches(text, re, "Hide reasoning or make it natural: \"Here's my take:\" instead of \"Let me think step by step:\"")
          }
        }
      ),

      Pattern.new(
        id: 26, name: "Excessive structure", category: :style, weight: 3,
        description: "Over-formatted responses: too many headers, nested bullets, or numbered lists for simple content.",
        detector: ->(text) {
          results = []
          words = TextUtils.word_count(text)

          headers = (text.scan(/^\#{1,6}\s+.+$/m) || []).length
          bullets = (text.scan(/^\s*[-*+]\s+/m) || []).length
          numbered = (text.scan(/^\s*\d+\.\s+/m) || []).length

          if words < 300 && headers >= 3
            results << {
              match: "#{headers} headers in #{words} words",
              index: 0, line: 1, column: 1,
              suggestion: "Too many headers for short content. Use prose instead.",
              confidence: "medium",
            }
          end

          if words < 200 && (bullets + numbered) >= 8
            results << {
              match: "#{bullets + numbered} list items in #{words} words",
              index: 0, line: 1, column: 1,
              suggestion: "Excessive lists. Could this be a paragraph instead?",
              confidence: "medium",
            }
          end

          structure_headers = /^#+\s*(?:overview|key (?:points|takeaways)|summary|conclusion|introduction|background)\s*:?\s*$/im
          results.concat TextUtils.find_matches(text, structure_headers, "Formulaic structure. Let content flow naturally.", confidence: "medium")

          results
        }
      ),

      Pattern.new(
        id: 27, name: "Confidence calibration", category: :communication, weight: 3,
        description: 'Artificially hedged or over-confident phrasing: "I\'m confident that...", "It\'s worth noting..."',
        detector: ->(text) {
          calibration_patterns = [
            { regex: /\bI'?m confident (?:that|in)\b/i, fix: "State the fact without prefacing confidence" },
            { regex: /\bit'?s worth (?:noting|mentioning|pointing out) that\b/i, fix: "Just say it" },
            { regex: /\binterestingly (?:enough)?,?\b/i, fix: "Let reader decide if interesting" },
            { regex: /\bsurprisingly,?\s/i, fix: "State the fact; surprise is implied" },
            { regex: /\bimportantly,?\s/i, fix: "Let reader judge importance" },
            { regex: /\bsignificantly,?\s/i, fix: "Be specific about the significance" },
            { regex: /\bnotably,?\s/i, fix: "Just state the notable thing" },
            { regex: /\bcertainly,?\s/i, fix: "Remove or state with evidence" },
            { regex: /\bundoubtedly,?\s/i, fix: "Remove or cite evidence" },
            { regex: /\bwithout (?:a )?doubt,?\s/i, fix: "Remove or cite evidence" },
          ]
          calibration_patterns.flat_map { |p|
            TextUtils.find_matches(text, p[:regex], p[:fix])
          }
        }
      ),

      Pattern.new(
        id: 28, name: "Acknowledgment loops", category: :communication, weight: 4,
        description: 'Restating the question before answering: "You\'re asking about X. X is..."',
        detector: ->(text) {
          ack_patterns = [
            /\byou'?re asking (?:about|whether|if|how|why|what)\b/i,
            /\bthe question of (?:whether|how|why|what)\b/i,
            /\bwhen it comes to your question\b/i,
            /\bin (?:terms of|response to|answer to) your question\b/i,
            /\bto (?:answer|address) your question\b/i,
            /\byour question (?:about|regarding|concerning)\b/i,
            /\bthat'?s a (?:great|good|interesting) question\. (?:the|it|so)\b/i,
            /\bI understand you'?re (?:asking|wondering|curious)\b/i,
          ]
          ack_patterns.flat_map { |re|
            TextUtils.find_matches(text, re, "Just answer. Don't restate the question.")
          }
        }
      ),
    ].freeze

    # ── Registry ─────────────────────────────────────────

    class Registry
      def initialize
        @patterns = PATTERNS.dup
      end

      def all
        @patterns
      end

      def find(id)
        @patterns.find { |p| p.id == id }
      end

      def by_category(category)
        @patterns.select { |p| p.category == category }
      end

      def categories
        @patterns.map(&:category).uniq
      end

      def list
        @patterns.map { |p| { id: p.id, name: p.name, category: p.category, weight: p.weight } }
      end

      def add(pattern)
        raise ArgumentError, "Pattern must have id, name, and detector" unless pattern.id && pattern.name && pattern.detector
        @patterns << pattern
      end

      def remove(id)
        @patterns.reject! { |p| p.id == id }
      end
    end
  end
end
