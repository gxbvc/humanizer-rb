# frozen_string_literal: true

module Humanizer
  module Vocabulary
    # ── Tier 1: Dead Giveaways ─────────────────────────────
    # Words that appear 5-20x more often in AI text than human text.
    TIER_1 = %w[
      delve delving delved delves
      tapestry vibrant crucial comprehensive
      intricate intricacies pivotal testament
      landscape bustling nestled realm
      meticulous meticulously complexities
      embark embarking embarked
      robust
      showcasing showcase showcased showcases
      underscores underscoring underscored
      fostering foster fostered fosters
      seamless seamlessly groundbreaking renowned
      synergy synergies
      leverage leveraging leveraged
      garner garnered garnering
      interplay enduring
      enhance enhanced enhancing enhancement
      tapestry testament additionally daunting
      ever-evolving
      underscore
      unpack unpacking unpacked
      unraveling unravel
      holistic holistically synergistic
      actionable impactful learnings cadence bandwidth
      net-net value-add
    ].freeze

    # Multi-word tier 1 entries (need separate handling)
    TIER_1_PHRASES = [
      "game changer", "game-changing", "game-changer",
      "deep dive", "deep-dive", "at its core",
      "best practices", "best-practices", "best practice",
      "thought leader", "thought leadership",
    ].freeze

    # ── Tier 2: Suspicious in Density ──────────────────────
    TIER_2 = %w[
      furthermore moreover notably consequently subsequently
      accordingly nonetheless henceforth indeed specifically
      essentially ultimately arguably fundamentally inherently
      profoundly
      encompassing encompasses encompassed
      endeavour endeavor endeavoring
      elevate elevated elevating
      alleviate alleviating
      streamline streamlined streamlining
      harness harnessing harnessed
      unleash unleashing unleashed
      revolutionize revolutionizing revolutionized
      transformative transformation paramount multifaceted
      spearhead spearheading spearheaded
      bolster bolstering bolstered
      catalyze catalyst catalyzed cornerstone
      reimagine reimagining reimagined
      empower empowering empowerment empowered
      navigate navigating navigated
      poised myriad nuanced nuance nuances
      paradigm paradigms paradigm-shifting
      holistic holistically
      utilize utilizing utilization utilized
      facilitate facilitated facilitating facilitation
      elucidate elucidating
      illuminate illuminating illuminated
      invaluable cutting-edge innovative innovation
      align aligns aligning alignment
      dynamic dynamics impactful agile
      scalable scalability proactive proactively synergistic
      optimize optimizing optimization
      resonate resonating resonated resonates
      underscore underscored
      cultivate cultivating cultivated
      galvanize galvanizing
      invigorate invigorating
      juxtapose juxtaposing juxtaposition
      underscore bolster
      augment augmenting augmented
      proliferate proliferating proliferation
      burgeoning nascent ubiquitous plethora myriad
      quintessential eclectic indelible
      overarching underpinning underpinnings
    ].freeze

    # ── Tier 3: Context-Dependent ──────────────────────────
    TIER_3 = %w[
      significant significantly important importantly
      effective effectively efficient efficiently
      diverse diversity unique uniquely
      key vital vitally critical critically
      essential essentially valuable notable
      remarkable remarkably substantial substantially
      considerable considerably noteworthy
      prominent prominently influential
      thoughtful thoughtfully insightful insightfully
      meaningful meaningfully purposeful purposefully
      deliberate deliberately strategic strategically
      integral indispensable instrumental imperative
      exemplary commendable praiseworthy
      sophisticated profound compelling captivating
      exquisite impeccable formidable stellar
      exceptional exceptionally extraordinary
      unparalleled unprecedented monumental
      groundbreaking trailblazing visionary
      world-class state-of-the-art best-in-class
    ].freeze

    # ── AI Phrases ─────────────────────────────────────────
    # Multi-word phrases that strongly signal AI authorship.
    AI_PHRASES = [
      # "In today's..." openers
      { pattern: /\bin today'?s (digital age|fast-paced world|rapidly evolving|ever-changing|modern|interconnected)\b/i, tier: 1, fix: "(remove or be specific about what changed)" },
      { pattern: /\bin today'?s world\b/i, tier: 2, fix: "(remove or be specific)" },

      # "It is [worth/important] to note"
      { pattern: /\bit is (worth|important to|essential to|crucial to) not(?:e|ing) that\b/i, tier: 1, fix: "(remove — just state the fact)" },
      { pattern: /\bit should be noted that\b/i, tier: 1, fix: "(remove — just state the fact)" },
      { pattern: /\bit bears mentioning that\b/i, tier: 1, fix: "(remove — just state the fact)" },

      # Journey metaphors
      { pattern: /\bpave the way (?:for|to)\b/i, tier: 1, fix: "enable / allow / lead to" },
      { pattern: /\bat the forefront of\b/i, tier: 1, fix: "leading / first in" },
      { pattern: /\bnavigate the (?:complexities|challenges|landscape)\b/i, tier: 1, fix: "handle / deal with / work through" },
      { pattern: /\bharness the (?:power|potential|capabilities) of\b/i, tier: 1, fix: "use" },
      { pattern: /\bembark on a journey\b/i, tier: 1, fix: "start / begin" },
      { pattern: /\bpush the boundaries\b/i, tier: 1, fix: "(be specific about what changed)" },
      { pattern: /\bfoster a (?:culture|environment|atmosphere|sense) of\b/i, tier: 1, fix: "build / create / encourage" },
      { pattern: /\bunlock the (?:potential|power|full|true)\b/i, tier: 1, fix: "enable / use / improve" },
      { pattern: /\bserves as a testament\b/i, tier: 1, fix: "shows / proves / demonstrates" },
      { pattern: /\bplays a (?:crucial|pivotal|vital|key|significant|important|critical) role\b/i, tier: 1, fix: "matters for / helps / is important to" },
      { pattern: /\bin the realm of\b/i, tier: 1, fix: "in" },
      { pattern: /\bdelve into\b/i, tier: 1, fix: "explore / examine / look at" },
      { pattern: /\bthe landscape of\b/i, tier: 1, fix: "(be specific — what part of the field?)" },
      { pattern: /\bnestled (?:in|within|among)\b/i, tier: 1, fix: "located in / in / near" },

      # Abstract verb phrases
      { pattern: /\brise to the (?:occasion|challenge)\b/i, tier: 2, fix: "handle / face / tackle" },
      { pattern: /\bstand at the (?:crossroads|intersection)\b/i, tier: 2, fix: "(be specific about the choice)" },
      { pattern: /\bshape the (?:future|trajectory|direction)\b/i, tier: 2, fix: "(be specific about how)" },
      { pattern: /\btip of the iceberg\b/i, tier: 2, fix: "one example / a small part" },
      { pattern: /\bdouble-edged sword\b/i, tier: 2, fix: "has tradeoffs / cuts both ways" },
      { pattern: /\ba testament to\b/i, tier: 1, fix: "shows / proves" },
      { pattern: /\bthe dawn of\b/i, tier: 2, fix: "the start of / the beginning of" },
      { pattern: /\bthe fabric of\b/i, tier: 1, fix: "(be concrete)" },
      { pattern: /\bthe tapestry of\b/i, tier: 1, fix: "(be concrete)" },

      # Hedging stacks
      { pattern: /\bcould potentially\b/i, tier: 1, fix: "could / might" },
      { pattern: /\bmight possibly\b/i, tier: 1, fix: "might" },
      { pattern: /\bcould possibly\b/i, tier: 1, fix: "could" },
      { pattern: /\bperhaps potentially\b/i, tier: 1, fix: "perhaps / maybe" },
      { pattern: /\bmay potentially\b/i, tier: 1, fix: "may" },
      { pattern: /\bcould conceivably\b/i, tier: 1, fix: "could" },

      # Chatbot filler
      { pattern: /\bI hope this helps\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\blet me know if (?:you|there)\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bwould you like me to\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bfeel free to\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bdon'?t hesitate to\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bhappy to help\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bhere is (?:a |an |the )?(?:comprehensive |brief |quick )?(?:overview|summary|breakdown|list|guide|explanation|look)\b/i, tier: 1, fix: "(remove — start with the content)" },
      { pattern: /\bI'?d be happy to\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bis there anything else\b/i, tier: 1, fix: "(remove)" },

      # Sycophantic
      { pattern: /\bgreat question\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bexcellent (?:question|point|observation)\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bthat'?s a (?:great|excellent|wonderful|fantastic|good|insightful|thoughtful) (?:question|point|observation)\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\byou'?re absolutely right\b/i, tier: 1, fix: "(remove or address the substance)" },
      { pattern: /\byou raise a (?:great|good|excellent|valid|important) point\b/i, tier: 1, fix: "(remove or address the substance)" },

      # Cutoff disclaimers
      { pattern: /\bas of (?:my|this) (?:last|latest|most recent) (?:training|update|knowledge)\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bwhile (?:specific )?details are (?:limited|scarce|not available)\b/i, tier: 1, fix: "(remove — research it or omit the claim)" },
      { pattern: /\bbased on (?:available|my|current) (?:information|knowledge|understanding|data)\b/i, tier: 1, fix: "(remove)" },
      { pattern: /\bup to my (?:last )?training\b/i, tier: 1, fix: "(remove)" },

      # Generic conclusions
      { pattern: /\bthe future (?:looks|is|remains) bright\b/i, tier: 1, fix: "(end with a specific fact or plan)" },
      { pattern: /\bexciting times (?:lie|lay|are) ahead\b/i, tier: 1, fix: "(end with a specific fact or plan)" },
      { pattern: /\bcontinue (?:this|their|our|the) journey\b/i, tier: 1, fix: "(be specific about what happens next)" },
      { pattern: /\bjourney towards? (?:excellence|success|greatness)\b/i, tier: 1, fix: "(be specific)" },
      { pattern: /\bstep in the right direction\b/i, tier: 1, fix: "(be specific about the outcome)" },
      { pattern: /\bonly time will tell\b/i, tier: 1, fix: "(end with what you actually know)" },
      { pattern: /\bthe possibilities are (?:endless|limitless|infinite)\b/i, tier: 1, fix: "(be specific about what's possible)" },
      { pattern: /\bpoised for (?:growth|success|greatness|expansion)\b/i, tier: 1, fix: "(cite evidence or remove)" },
      { pattern: /\bwatch this space\b/i, tier: 2, fix: "(end with something concrete)" },
      { pattern: /\bstay tuned\b/i, tier: 2, fix: "(end with something concrete)" },
      { pattern: /\bremains to be seen\b/i, tier: 2, fix: "(state what you do know)" },

      # Formulaic filler
      { pattern: /\bin order to\b/i, tier: 2, fix: "to" },
      { pattern: /\bdue to the fact that\b/i, tier: 1, fix: "because" },
      { pattern: /\bat this point in time\b/i, tier: 1, fix: "now" },
      { pattern: /\bin the event that\b/i, tier: 1, fix: "if" },
      { pattern: /\bhas the ability to\b/i, tier: 1, fix: "can" },
      { pattern: /\bfor the purpose of\b/i, tier: 1, fix: "to / for" },
      { pattern: /\bin light of the fact that\b/i, tier: 1, fix: "because / since" },
      { pattern: /\bfirst and foremost\b/i, tier: 2, fix: "first" },
      { pattern: /\blast but not least\b/i, tier: 2, fix: "finally" },
      { pattern: /\bat the end of the day\b/i, tier: 2, fix: "(remove or be specific)" },
      { pattern: /\bwhen it comes to\b/i, tier: 2, fix: "for / regarding" },
      { pattern: /\bthe fact of the matter is\b/i, tier: 1, fix: "(remove — just state it)" },
      { pattern: /\bin terms of\b/i, tier: 3, fix: "for / about / regarding" },
      { pattern: /\bat its core\b/i, tier: 2, fix: "(remove or be specific)" },
      { pattern: /\bit goes without saying\b/i, tier: 2, fix: "(if it goes without saying, don't say it)" },
      { pattern: /\bneedless to say\b/i, tier: 2, fix: "(if needless to say, don't say it)" },

      # v2.2 additions
      { pattern: /\blet'?s dive in\b/i, tier: 1, fix: "(just start)" },
      { pattern: /\blet'?s (?:break this|break it) down\b/i, tier: 1, fix: "(just explain)" },
      { pattern: /\bhere'?s the thing\b/i, tier: 2, fix: "(just say it)" },
      { pattern: /\bthe reality is\b/i, tier: 2, fix: "(state the fact)" },
      { pattern: /\bmoving forward\b/i, tier: 2, fix: "next / from now on" },
      { pattern: /\bcircle back\b/i, tier: 1, fix: "return to / revisit" },
      { pattern: /\btouch base\b/i, tier: 1, fix: "talk / check in" },
      { pattern: /\bgoing forward\b/i, tier: 2, fix: "from now on" },
      { pattern: /\bkey takeaways?\b/i, tier: 1, fix: "main point(s)" },
      { pattern: /\bvalue proposition\b/i, tier: 2, fix: "benefit / value" },
      { pattern: /\bcore competenc(?:y|ies)\b/i, tier: 2, fix: "strength(s)" },
      { pattern: /\bbest-in-class\b/i, tier: 1, fix: "excellent / (be specific)" },
      { pattern: /\bworld-class\b/i, tier: 1, fix: "(be specific)" },
      { pattern: /\bcutting-edge\b/i, tier: 1, fix: "(be specific)" },
      { pattern: /\bstate-of-the-art\b/i, tier: 1, fix: "(be specific or cite)" },
      { pattern: /\bgold standard\b/i, tier: 2, fix: "(cite the standard)" },
      { pattern: /\blow-hanging fruit\b/i, tier: 1, fix: "easy wins / quick wins" },
      { pattern: /\bpain points?\b/i, tier: 1, fix: "problem(s)" },
      { pattern: /\bdeep dive\b/i, tier: 1, fix: "detailed look / analysis" },
      { pattern: /\bparadigm shift\b/i, tier: 1, fix: "major change" },
      { pattern: /\bdouble-click (?:on)?\b/i, tier: 1, fix: "examine / look closer at" },
      { pattern: /\bloop (?:you |me |them )in\b/i, tier: 2, fix: "include / inform" },
      { pattern: /\btable this\b/i, tier: 2, fix: "postpone / set aside" },
      { pattern: /\bpivot to\b/i, tier: 2, fix: "switch to / change to" },
      { pattern: /\bsynch? (?:up )?(?:on|about)\b/i, tier: 2, fix: "discuss / align on" },
      { pattern: /\brun it up the flagpole\b/i, tier: 1, fix: "propose / suggest" },
      { pattern: /\bboil the ocean\b/i, tier: 1, fix: "attempt too much" },
      { pattern: /\bmove the needle\b/i, tier: 1, fix: "make progress / have impact" },
      { pattern: /\bopen the kimono\b/i, tier: 1, fix: "share / be transparent" },
      { pattern: /\bdrink the Kool-Aid\b/i, tier: 2, fix: "believe / accept" },
    ].freeze

    # ── Function Words ─────────────────────────────────────
    FUNCTION_WORDS = %w[
      the be to of and a in that have I it for not on with
      he as you do at this but his by from they we say her
      she or an will my one all would there their what so
      up out if about who get which go me when make can like
      time no just him know take people into year your good
      some could them see other than then now look only come
      its over think also back after use two how our work
      first well way even new want because any these give
      day most us
    ].freeze
  end
end
