# humanizer-rb

Detect AI-generated writing patterns. Scores text 0-100 using 32 pattern detectors, 500+ vocabulary terms, and statistical text analysis.

> **Ruby port of [humanizer](https://github.com/christiangenco/humanizer)** (Node.js). Same detection engine, same scoring algorithm, zero dependencies.

## Installation

Add to your Gemfile:

```ruby
gem "humanizer-rb"
```

Or install directly:

```sh
gem install humanizer-rb
```

## Usage

### Ruby API

```ruby
require "humanizer"

# Quick score (0-100, higher = more AI-like)
Humanizer.score("Your text here")
# => 42

# Full analysis
result = Humanizer.analyze("Your text here")
result.score              # => 42
result.pattern_score      # => 48
result.uniformity_score   # => 30
result.total_matches      # => 7
result.word_count         # => 156
result.findings           # => [{ pattern_id: 7, pattern_name: "AI vocabulary", ... }]
result.categories         # => { content: { matches: 2, ... }, language: { matches: 5, ... } }
result.stats              # => #<Humanizer::Stats::Result burstiness: 0.31, ...>
result.summary            # => "Score: 42/100 (moderately AI-influenced)..."

# Humanization suggestions with priorities
suggestions = Humanizer.humanize("Your text here")
suggestions[:critical]    # Dead giveaways (weight 4-5)
suggestions[:important]   # Noticeable patterns (weight 2-3)
suggestions[:minor]       # Subtle tells (weight 1)
suggestions[:guidance]    # Actionable writing tips
suggestions[:style_tips]  # Statistical improvement suggestions

# Safe mechanical auto-fixes
fixed = Humanizer.auto_fix("In order to utilize this...")
fixed[:text]   # => "to use this..."
fixed[:fixes]  # => ['"in order to" → "to"', '"utilize" → "use"']
```

### CLI

```sh
# Quick score
echo "This is a testament to..." | humanizer score
# => 🟡 38/100

# Full analysis
humanizer analyze essay.txt

# Markdown report
humanizer report article.txt > report.md

# Humanization suggestions
humanizer suggest article.txt

# Auto-fix + suggestions
humanizer humanize --autofix -f article.txt

# Statistical analysis only
humanizer stats essay.txt

# JSON output
humanizer analyze --json essay.txt
```

#### Score badges

| Score | Badge | Label |
|-------|-------|-------|
| 0-25  | 🟢 | Mostly human-sounding |
| 26-50 | 🟡 | Lightly AI-touched |
| 51-75 | 🟠 | Moderately AI-influenced |
| 76-100 | 🔴 | Heavily AI-generated |

## How it works

The score combines three signals:

1. **Pattern matches (70%)** — 32 detectors scan for AI writing patterns across 5 categories:
   - **Content**: significance inflation, promotional language, vague attributions
   - **Language**: AI vocabulary (500+ words in 3 tiers), copula avoidance, synonym cycling, and three psycholinguistic signals (see below)
   - **Style**: em dash overuse, boldface overuse, emoji decoration, curly quotes
   - **Communication**: chatbot artifacts, sycophantic tone, reasoning chain artifacts
   - **Filler**: wordy phrases, excessive hedging, generic conclusions

2. **Statistical uniformity (30%)** — measures how "robotic" the text structure is:
   - Burstiness (sentence length variation between consecutive sentences)
   - Type-token ratio (vocabulary diversity)
   - Trigram repetition
   - Sentence length standard deviation

3. **Category breadth** — more diverse AI signals = higher score

### Psycholinguistic signals (new in 0.2.0)

Clark, Martin & Mahowald, ["Why is AI-generated language so hard to understand?"](https://arxiv.org/abs/2610.29162) (arXiv 2610.29162, CC BY 4.0, Oct 2026) compare frontier model text with human text and find constructions that cost human readers effort and that models overuse. The paper reads them from a dependency parse. This gem has no parser, so it uses word lists and patterns for three of them:

| # | Detector | Example | Notes |
|---|----------|---------|-------|
| 30 | Inanimate subject with animate verb | "the parser swallows that error", "`fetch()` wants a token" | Verbs code docs use for things ("expects", "returns", "takes") are not on the list. |
| 31 | Reduced object relative clauses | "the approach we chose", "the state you set" | Humans write these too, so it fires only at 3 or more, at 1 per 100 words or denser. Weight 1. |
| 32 | Ad hoc denominal verbs | "footnote it", "roadmap this" | Short list of nouns that are not normally verbs. |

Not built, because each needs a parser or a reference corpus: dependency length, stacked noun compounds (3 or more nouns in a row), and rare-n-gram rate. These are heuristics, not the paper's measurements, and a hit is a hint, not proof.

## Rails integration

```ruby
# Gemfile
gem "humanizer-rb"

# app/models/email.rb
class Email < ApplicationRecord
  before_save :calculate_humanizer_score,
    if: -> { body_changed? && body.present? }

  private

  def calculate_humanizer_score
    self.humanizer_score = Humanizer.score(body)
  end
end
```

## License

MIT — see [LICENSE](LICENSE).
