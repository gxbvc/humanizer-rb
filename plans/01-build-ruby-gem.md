# Plan 01: Build humanizer-rb Ruby Gem

## Goal

Port the humanizer AI writing detection tool from Node.js (`~/tools/humanizer`) to a Ruby gem. The gem provides a scoring engine that detects AI writing patterns in text and returns a 0-100 score with detailed findings.

## Source Reference

The JS source to port lives at `~/tools/humanizer/src/`:
- `vocabulary.js` (673 lines) — 500+ AI words/phrases in 3 tiers
- `patterns.js` (1134 lines) — 28 pattern detectors (24 original + 4 added in v2.2)
- `stats.js` (275 lines) — Statistical text analysis (burstiness, TTR, trigrams, readability)
- `analyzer.js` (419 lines) — Composite scoring engine

All logic is pure computation — regex, string manipulation, basic statistics. No ML models, no external APIs, no dependencies.

## Gem Structure

```
~/projects/humanizer/
├── humanizer.gemspec
├── Gemfile
├── Rakefile
├── LICENSE
├── README.md
├── lib/
│   ├── humanizer.rb              # Main entry point
│   └── humanizer/
│       ├── version.rb
│       ├── vocabulary.rb          # Port of vocabulary.js
│       ├── patterns.rb            # Port of patterns.js
│       ├── stats.rb               # Port of stats.js
│       ├── analyzer.rb            # Port of analyzer.js
│       └── text_utils.rb          # Shared helpers (tokenize, word_count, find_matches, etc.)
├── test/
│   ├── test_helper.rb
│   ├── vocabulary_test.rb
│   ├── patterns_test.rb
│   ├── stats_test.rb
│   ├── analyzer_test.rb
│   └── calibration_test.rb       # Known AI vs human text samples
└── bin/
    └── humanizer                  # Optional CLI (not critical)
```

## Public API

```ruby
require "humanizer"

# Quick score (0-100, higher = more AI-like)
Humanizer.score("Your text here")
# => 42

# Full analysis with details
result = Humanizer.analyze("Your text here")
result.score              # => 42
result.pattern_score      # => 48
result.uniformity_score   # => 30
result.total_matches      # => 7
result.word_count         # => 156
result.findings           # => [{ pattern_id: 7, pattern_name: "AI vocabulary", ... }]
result.categories         # => { content: { matches: 2, ... }, language: { matches: 5, ... } }
result.stats              # => { burstiness: 0.31, type_token_ratio: 0.42, ... }
result.summary            # => "Score: 42/100 (moderately AI-influenced)..."
```

## Module Breakdown

### `Humanizer::Vocabulary` (port of vocabulary.js)

Constants:
- `TIER_1` — Array of ~85 dead giveaway words (strings)
- `TIER_2` — Array of ~130 suspicious-in-density words
- `TIER_3` — Array of ~70 context-dependent words
- `AI_PHRASES` — Array of hashes: `{ pattern: Regexp, tier: Integer, fix: String }`
- `FUNCTION_WORDS` — Array of 100 common function words

Port notes:
- JS regexes with `/gi` flags → Ruby `Regexp.new(source, Regexp::IGNORECASE)`. All matching done with `scan` or `gsub` for global.
- The word lists are just string arrays — direct copy.
- The AI_PHRASES array has ~90 entries, each with a regex pattern, tier (1-3), and fix string. Convert JS regex literals to Ruby regex literals.

### `Humanizer::TextUtils` (shared helpers)

```ruby
module Humanizer
  module TextUtils
    # Tokenize text into lowercase words
    def self.tokenize(text)
      text.downcase.gsub(/[^\w\s'-]/, " ").split(/\s+/).reject(&:empty?)
    end

    # Word count
    def self.word_count(text)
      text.strip.split(/\s+/).reject(&:empty?).length
    end

    # Find all regex matches with line/column info
    # Returns array of Match structs
    def self.find_matches(text, regex, suggestion, confidence: "high")
      results = []
      text.each_line.with_index(1) do |line, line_num|
        line.scan(regex) do
          match = Regexp.last_match
          results << {
            match: match[0],
            line: line_num,
            column: match.begin(0) + 1,
            suggestion: suggestion,
            confidence: confidence
          }
        end
      end
      results
    end

    # Build word-boundary regex for a word/phrase
    def self.word_regex(word)
      escaped = Regexp.escape(word)
      /\b#{escaped}\b/i
    end
  end
end
```

### `Humanizer::Patterns` (port of patterns.js)

Each of the 28 pattern detectors becomes a hash or simple object:

```ruby
module Humanizer
  module Patterns
    Pattern = Struct.new(:id, :name, :category, :description, :weight, :detector, keyword_init: true)

    PATTERNS = [
      Pattern.new(
        id: 1,
        name: "Significance inflation",
        category: :content,
        description: "Inflated claims about significance, legacy, or broader trends.",
        weight: 4,
        detector: ->(text) { detect_significance_inflation(text) }
      ),
      # ... 27 more patterns
    ].freeze

    class << self
      def all = PATTERNS
      def find(id) = PATTERNS.find { |p| p.id == id }
      def by_category(cat) = PATTERNS.select { |p| p.category == cat }

      # Each detect_* method returns array of match hashes
      def detect_significance_inflation(text)
        phrases = [/marking a pivotal/i, /pivotal moment/i, ...] # from JS SIGNIFICANCE_PHRASES
        phrases.flat_map { |re| TextUtils.find_matches(text, re, "Remove inflated significance claim.") }
      end

      # ... etc for all 28 patterns
    end
  end
end
```

Port notes:
- JS `detect(text)` methods → Ruby class methods or lambdas
- The pattern 7 (AI vocabulary) detector is the most complex — it scans all 3 tiers + phrases. Port the tier logic exactly (tier 1 always flags, tier 2 flags if ≥2 matches, tier 3 flags at >3% density).
- Patterns 10 (rule of three) and 11 (synonym cycling) have more complex logic — port the sentence iteration logic.

### `Humanizer::Stats` (port of stats.js)

```ruby
module Humanizer
  module Stats
    Result = Struct.new(
      :word_count, :unique_word_count, :sentence_count, :paragraph_count,
      :avg_word_length, :avg_sentence_length, :sentence_length_std_dev,
      :sentence_length_variation, :burstiness, :type_token_ratio,
      :function_word_ratio, :trigram_repetition, :avg_paragraph_length,
      :flesch_kincaid, :sentence_lengths,
      keyword_init: true
    )

    class << self
      def compute(text)
        # Port of computeStats()
      end

      def uniformity_score(stats)
        # Port of computeUniformityScore()
        # Same thresholds: burstiness, sentence variation, TTR, trigram repetition
      end

      def split_sentences(text)
        # Port of splitSentences() — handle abbreviations
      end

      def estimate_syllables(word)
        # Port of estimateSyllables() — English heuristic
      end

      def compute_ngram_repetition(words, n)
        # Port of computeNgramRepetition()
      end
    end
  end
end
```

### `Humanizer::Analyzer` (port of analyzer.js)

```ruby
module Humanizer
  module Analyzer
    Result = Struct.new(
      :score, :pattern_score, :uniformity_score, :total_matches,
      :word_count, :stats, :categories, :findings, :summary,
      keyword_init: true
    )

    class << self
      def analyze(text, verbose: false, patterns_to_check: nil, include_stats: true)
        # Port of analyze() function
        # 1. Compute stats
        # 2. Run all pattern detectors
        # 3. Calculate pattern score (density + breadth + category diversity)
        # 4. Calculate composite score (70% pattern + 30% uniformity)
        # 5. Build summary
      end

      def score(text)
        analyze(text).score
      end

      private

      def calculate_pattern_score(findings, words)
        # Port exactly: density (log scale), breadth bonus, category bonus
      end

      def calculate_composite_score(pattern_score, uniformity_score, findings)
        # Port exactly: 70/30 blend, findings guard
      end
    end
  end
end
```

### `Humanizer` (top-level module)

```ruby
require "humanizer/version"
require "humanizer/text_utils"
require "humanizer/vocabulary"
require "humanizer/patterns"
require "humanizer/stats"
require "humanizer/analyzer"

module Humanizer
  def self.score(text)
    Analyzer.score(text)
  end

  def self.analyze(text, **opts)
    Analyzer.analyze(text, **opts)
  end
end
```

## Gemspec

```ruby
Gem::Specification.new do |spec|
  spec.name          = "humanizer"
  spec.version       = Humanizer::VERSION
  spec.authors       = ["Christian Genco"]
  spec.email         = ["christian@gen.co"]
  spec.summary       = "Detect AI-generated writing patterns"
  spec.description   = "Scores text 0-100 for AI writing patterns using 28 pattern detectors, 500+ vocabulary terms, and statistical text analysis."
  spec.homepage      = "https://github.com/cgenco/humanizer-rb"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files         = Dir["lib/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  # Zero runtime dependencies — all pure Ruby
end
```

## Testing

Use Minitest (matches Rails conventions). Key tests:

### `calibration_test.rb`

Test against known AI and human text samples to verify scoring accuracy:

```ruby
class CalibrationTest < Minitest::Test
  def test_obvious_ai_text_scores_high
    ai_text = "In today's rapidly evolving digital landscape, it is crucial to delve into the multifaceted tapestry of innovation. This serves as a testament to the transformative potential of leveraging cutting-edge synergies. The future looks bright. I hope this helps!"
    assert Humanizer.score(ai_text) >= 60
  end

  def test_human_text_scores_low
    human_text = "I tried the new coffee shop on 5th. The espresso was burnt and cost $7. Won't go back. Their pastries were fine though — the almond croissant reminded me of the one at Tartine in SF."
    assert Humanizer.score(human_text) <= 25
  end

  def test_cold_email_scores
    # Use the Fortinet email drafts from triggmagic as test cases
    email = "Mike, congrats on wrapping Accelerate — Mandalay Bay with 3,000+ attendees is no small feat.\n\nCurious: when you're planning the closing party entertainment for next year's conference, how early do you start locking that in?"
    assert Humanizer.score(email) <= 30, "Well-written cold email should score low"
  end
end
```

### `patterns_test.rb`

Test each pattern detector individually:

```ruby
class PatternsTest < Minitest::Test
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
    assert chatbot_finding
  end
end
```

### `stats_test.rb`

Verify statistical computations match expected values:

```ruby
class StatsTest < Minitest::Test
  def test_burstiness_high_for_varied_text
    text = "Short. This is a much longer sentence with many more words in it. No. Another long one follows with plenty of variation in the rhythm and cadence."
    stats = Humanizer::Stats.compute(text)
    assert stats.burstiness > 0.4
  end

  def test_burstiness_low_for_uniform_text
    text = "Each sentence is about this long. Every sentence is about this long. All sentences are about this long. No sentence is much different."
    stats = Humanizer::Stats.compute(text)
    assert stats.burstiness < 0.3
  end
end
```

## Implementation Order

1. **`text_utils.rb`** — Shared helpers (tokenize, word_count, find_matches, word_regex)
2. **`vocabulary.rb`** — Copy over all word lists and convert regex patterns
3. **`stats.rb`** — Port statistical analysis (most self-contained)
4. **`patterns.rb`** — Port all 28 pattern detectors (biggest file, ~600-800 lines)
5. **`analyzer.rb`** — Port composite scoring engine
6. **`humanizer.rb`** — Top-level module, wire everything up
7. **Tests** — Write calibration, pattern, and stats tests
8. **Gemspec + README**

## Regex Conversion Notes

JS → Ruby regex conversion patterns:
- `/\bword\b/gi` → `/\bword\b/i` (Ruby's `scan` handles global matching)
- `/pattern/g` → `/pattern/` (use `text.scan(regex)` for global)
- `\u201C` → `\u{201C}` in Ruby
- `\u{1F300}-\u{1F9FF}` Unicode ranges work the same in Ruby
- JS `?<=` lookbehind → Ruby supports this since 2.0
- JS named groups `(?<name>...)` → same in Ruby

## Estimated Size

- `vocabulary.rb`: ~400 lines (mostly data)
- `patterns.rb`: ~600-800 lines (28 detectors + helper phrase arrays)
- `stats.rb`: ~200 lines
- `analyzer.rb`: ~150 lines
- `text_utils.rb`: ~60 lines
- Tests: ~200 lines
- **Total: ~1,600-1,800 lines of Ruby**

## Usage in Mailer

Once published (or used via path), add to mailer's Gemfile:

```ruby
# In ~/projects/mailer/Gemfile
gem "humanizer", path: "../humanizer"
```

Then in the Email model:

```ruby
class Email < ApplicationRecord
  before_save :calculate_humanizer_score, if: -> { body_markdown_changed? && body_markdown.present? }

  private

  def calculate_humanizer_score
    self.humanizer_score = Humanizer.score(body_markdown)
  end
end
```
