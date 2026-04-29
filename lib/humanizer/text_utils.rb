# frozen_string_literal: true

module Humanizer
  module TextUtils
    module_function

    # Tokenize text into lowercase words
    def tokenize(text)
      text.downcase.gsub(/[^\w\s'-]/, " ").split(/\s+/).reject(&:empty?)
    end

    # Word count
    def word_count(text)
      text.strip.split(/\s+/).reject(&:empty?).length
    end

    # Find all regex matches with line/column info.
    # Returns array of hashes with :match, :index, :line, :column, :suggestion, :confidence
    def find_matches(text, regex, suggestion, confidence: "high")
      results = []
      lines = text.split("\n")
      offset = 0

      lines.each_with_index do |line, line_idx|
        line.scan(regex) do
          m = Regexp.last_match
          results << {
            match: m[0],
            index: offset + m.begin(0),
            line: line_idx + 1,
            column: m.begin(0) + 1,
            suggestion: suggestion.is_a?(Proc) ? suggestion.call(m[0]) : suggestion,
            confidence: confidence,
          }
        end
        offset += line.length + 1
      end
      results
    end

    # Count regex occurrences
    def count_matches(text, regex)
      m = text.scan(regex)
      m.length
    end

    # Build a case-insensitive word-boundary regex for a word/phrase
    def word_regex(word)
      escaped = Regexp.escape(word)
      /\b#{escaped}\b/i
    end
  end
end
