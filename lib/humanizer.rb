# frozen_string_literal: true

require "set"

require_relative "humanizer/version"
require_relative "humanizer/text_utils"
require_relative "humanizer/vocabulary"
require_relative "humanizer/stats"
require_relative "humanizer/patterns"
require_relative "humanizer/analyzer"
require_relative "humanizer/humanizer_engine"

module Humanizer
  # Quick score (0-100, higher = more AI-like)
  def self.score(text)
    Analyzer.score(text)
  end

  # Full analysis with details
  def self.analyze(text, **opts)
    Analyzer.analyze(text, **opts)
  end

  # Humanization suggestions
  def self.humanize(text, **opts)
    HumanizerEngine.humanize(text, **opts)
  end

  # Safe mechanical auto-fixes
  def self.auto_fix(text)
    HumanizerEngine.auto_fix(text)
  end
end
