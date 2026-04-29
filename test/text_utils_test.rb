# frozen_string_literal: true

require "test_helper"

class TextUtilsTest < Minitest::Test
  def test_tokenize
    tokens = Humanizer::TextUtils.tokenize("Hello, World! How are you?")
    assert_includes tokens, "hello"
    assert_includes tokens, "world"
    assert_includes tokens, "how"
  end

  def test_word_count
    assert_equal 5, Humanizer::TextUtils.word_count("one two three four five")
    assert_equal 0, Humanizer::TextUtils.word_count("   ")
  end

  def test_find_matches
    text = "The cat sat on the mat."
    matches = Humanizer::TextUtils.find_matches(text, /\bcat\b/i, "Replace cat.")
    assert_equal 1, matches.length
    assert_equal "cat", matches[0][:match]
    assert_equal 1, matches[0][:line]
  end

  def test_find_matches_multiline
    text = "Line one.\nThe cat is here.\nLine three."
    matches = Humanizer::TextUtils.find_matches(text, /\bcat\b/i, "Found cat.")
    assert_equal 1, matches.length
    assert_equal 2, matches[0][:line]
  end

  def test_count_matches
    assert_equal 2, Humanizer::TextUtils.count_matches("the cat and the dog", /\bthe\b/i)
  end

  def test_word_regex
    regex = Humanizer::TextUtils.word_regex("delve")
    assert "We must delve into this" =~ regex
    refute "We must delved into this" =~ regex  # word boundary
  end
end
