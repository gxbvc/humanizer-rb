# frozen_string_literal: true

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

    EMPTY = Result.new(
      word_count: 0, unique_word_count: 0, sentence_count: 0, paragraph_count: 0,
      avg_word_length: 0, avg_sentence_length: 0, sentence_length_std_dev: 0,
      sentence_length_variation: 0, burstiness: 0, type_token_ratio: 0,
      function_word_ratio: 0, trigram_repetition: 0, avg_paragraph_length: 0,
      flesch_kincaid: 0, sentence_lengths: []
    ).freeze

    module_function

    def compute(text)
      return EMPTY if text.nil? || !text.is_a?(String) || text.strip.empty?

      words = TextUtils.tokenize(text)
      return EMPTY if words.empty?

      sentences = split_sentences(text)
      paragraphs = text.split(/\n\s*\n/).select { |p| p.strip.length > 0 }

      # Word-level stats
      word_count = words.length
      unique_words = words.uniq
      type_token_ratio = unique_words.length.to_f / word_count
      avg_word_length = words.sum { |w| w.length }.to_f / word_count

      # Sentence-level stats
      sentence_lengths = sentences.map { |s| TextUtils.tokenize(s).length }.select { |n| n > 0 }
      sentence_count = sentence_lengths.length

      avg_sentence_length = 0.0
      sentence_length_std_dev = 0.0
      sentence_length_variation = 0.0
      burstiness = 0.0

      if sentence_count > 1
        avg_sentence_length = sentence_lengths.sum.to_f / sentence_count

        variance = sentence_lengths.sum { |len| (len - avg_sentence_length) ** 2 }.to_f / sentence_count
        sentence_length_std_dev = Math.sqrt(variance)

        sentence_length_variation = avg_sentence_length > 0 ? sentence_length_std_dev / avg_sentence_length : 0.0

        consecutive_diff_sum = (1...sentence_lengths.length).sum { |i|
          (sentence_lengths[i] - sentence_lengths[i - 1]).abs
        }
        avg_consecutive_diff = consecutive_diff_sum.to_f / (sentence_lengths.length - 1)
        burstiness = avg_sentence_length > 0 ? avg_consecutive_diff / avg_sentence_length : 0.0
      elsif sentence_count == 1
        avg_sentence_length = sentence_lengths[0].to_f
      end

      # Function word ratio
      function_word_set = Vocabulary::FUNCTION_WORDS.map(&:downcase).to_set
      function_word_count = words.count { |w| function_word_set.include?(w) }
      function_word_ratio = function_word_count.to_f / word_count

      # N-gram repetition
      trigram_repetition = compute_ngram_repetition(words, 3)

      # Paragraph stats
      paragraph_count = paragraphs.length
      avg_paragraph_length = paragraph_count > 0 ?
        paragraphs.sum { |p| TextUtils.tokenize(p).length }.to_f / paragraph_count : 0.0

      # Readability (Flesch-Kincaid Grade Level)
      syllable_count = words.sum { |w| estimate_syllables(w) }
      flesch_kincaid = sentence_count > 0 ?
        0.39 * (word_count.to_f / sentence_count) + 11.8 * (syllable_count.to_f / word_count) - 15.59 : 0.0

      Result.new(
        word_count: word_count,
        unique_word_count: unique_words.length,
        sentence_count: sentence_count,
        paragraph_count: paragraph_count,
        avg_word_length: round3(avg_word_length),
        avg_sentence_length: round3(avg_sentence_length),
        sentence_length_std_dev: round3(sentence_length_std_dev),
        sentence_length_variation: round3(sentence_length_variation),
        burstiness: round3(burstiness),
        type_token_ratio: round3(type_token_ratio),
        function_word_ratio: round3(function_word_ratio),
        trigram_repetition: round3(trigram_repetition),
        avg_paragraph_length: round3(avg_paragraph_length),
        flesch_kincaid: round3(flesch_kincaid),
        sentence_lengths: sentence_lengths,
      )
    end

    # Compute uniformity score (0-100). Higher = more uniform/AI-like.
    def uniformity_score(stats)
      return 0 if stats.word_count == 0

      score = 0

      # Low burstiness = more AI-like (max 25 points)
      if stats.burstiness < 0.2 then score += 25
      elsif stats.burstiness < 0.35 then score += 18
      elsif stats.burstiness < 0.5 then score += 10
      elsif stats.burstiness < 0.65 then score += 5
      end

      # Low sentence length variation = more AI-like (max 25 points)
      if stats.sentence_length_variation < 0.2 then score += 25
      elsif stats.sentence_length_variation < 0.35 then score += 18
      elsif stats.sentence_length_variation < 0.5 then score += 10
      elsif stats.sentence_length_variation < 0.65 then score += 5
      end

      # Low type-token ratio = more repetitive/AI-like (max 20 points)
      if stats.word_count > 100
        if stats.type_token_ratio < 0.35 then score += 20
        elsif stats.type_token_ratio < 0.45 then score += 12
        elsif stats.type_token_ratio < 0.55 then score += 5
        end
      end

      # High trigram repetition = more AI-like (max 15 points)
      if stats.trigram_repetition > 0.15 then score += 15
      elsif stats.trigram_repetition > 0.1 then score += 10
      elsif stats.trigram_repetition > 0.05 then score += 5
      end

      # Abnormally uniform paragraph lengths (max 15 points)
      if stats.paragraph_count >= 3 && stats.sentence_count > 5
        if stats.sentence_length_std_dev < 3 && stats.avg_sentence_length > 10
          score += 15
        end
      end

      [score, 100].min
    end

    # Split text into sentences, handling abbreviations
    def split_sentences(text)
      cleaned = text
        .gsub(/\b(Mr|Mrs|Ms|Dr|Prof|Sr|Jr|etc|vs|approx|dept|est|vol)\./i, '\1' + "\u2024")
        .gsub(/\b([A-Z])\./,  '\1' + "\u2024")
        .gsub(/\b(\d+)\./,    '\1' + "\u2024")

      sentences = cleaned
        .split(/(?<=[.!?])\s+(?=[A-Z"'\u{201C}])|(?<=[.!?])$/)
        .map { |s| s.gsub("\u2024", ".").strip }
        .reject(&:empty?)

      sentences
    end

    # Estimate syllable count for a word (English heuristic)
    def estimate_syllables(word)
      w = word.downcase.gsub(/[^a-z]/, "")
      return 1 if w.length <= 3

      vowel_groups = w.scan(/[aeiouy]+/)
      count = vowel_groups.length > 0 ? vowel_groups.length : 1

      # Subtract silent e
      count -= 1 if w.end_with?("e") && !w.end_with?("le")
      # Subtract for -ed that doesn't create syllable
      count -= 1 if w.end_with?("ed") && w.length > 3 && w !~ /[aeiouy]ed$/

      [count, 1].max
    end

    # Compute n-gram repetition rate
    def compute_ngram_repetition(words, n)
      return 0.0 if words.length < n

      ngrams = Hash.new(0)
      (0..words.length - n).each do |i|
        gram = words[i, n].join(" ")
        ngrams[gram] += 1
      end

      total = ngrams.length
      return 0.0 if total == 0

      repeated = ngrams.values.count { |c| c > 1 }
      repeated.to_f / total
    end

    def round3(n)
      (n * 1000).round / 1000.0
    end
  end
end
