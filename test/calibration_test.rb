# frozen_string_literal: true

require "test_helper"

class CalibrationTest < Minitest::Test
  def test_obvious_ai_text_scores_high
    ai_text = "In today's rapidly evolving digital landscape, it is crucial to delve into the multifaceted tapestry of innovation. This serves as a testament to the transformative potential of leveraging cutting-edge synergies. The future looks bright. I hope this helps!"
    score = Humanizer.score(ai_text)
    assert score >= 60, "Obvious AI text should score >= 60, got #{score}"
  end

  def test_human_text_scores_low
    human_text = "I tried the new coffee shop on 5th. The espresso was burnt and cost $7. Won't go back. Their pastries were fine though — the almond croissant reminded me of the one at Tartine in SF."
    score = Humanizer.score(human_text)
    assert score <= 25, "Human-sounding text should score <= 25, got #{score}"
  end

  def test_cold_email_scores_low
    email = "Mike, congrats on wrapping Accelerate — Mandalay Bay with 3,000+ attendees is no small feat.\n\nCurious: when you're planning the closing party entertainment for next year's conference, how early do you start locking that in?"
    score = Humanizer.score(email)
    assert score <= 30, "Well-written cold email should score <= 30, got #{score}"
  end

  def test_chatbot_response_scores_high
    chatbot = "Great question! Here is a comprehensive overview of the topic. It's important to note that this is a multifaceted issue. Let me break this down for you. First and foremost, we need to consider the broader implications. I hope this helps! Let me know if you have any other questions."
    score = Humanizer.score(chatbot)
    assert score >= 50, "Chatbot response should score >= 50, got #{score}"
  end

  def test_mixed_text_scores_moderate
    mixed = "The company launched its new product last Tuesday. This groundbreaking innovation leverages cutting-edge technology to deliver a seamless user experience. We sold 500 units in the first week, mostly through our website."
    score = Humanizer.score(mixed)
    assert score >= 15 && score <= 70, "Mixed text should score 15-70, got #{score}"
  end

  def test_plain_factual_text_scores_low
    factual = "The meeting is at 3pm in room 204. Bring the Q3 numbers and the draft proposal. Sarah will dial in from Denver. We need to decide on the vendor by Friday or we lose the discount."
    score = Humanizer.score(factual)
    assert score <= 20, "Plain factual text should score <= 20, got #{score}"
  end
end
