# Changelog

## 0.2.0 (2026-10-22)

- Three new detectors from Clark, Martin & Mahowald (2026, arXiv:2610.29162): inanimate subject with animate verb (30), reduced object relative clauses (31, only at 3+ hits), ad hoc denominal verbs (32)
- Pattern count is now 32. Existing scores do not change unless a text has one of the new constructions

## 0.1.0 (2026-03-16)

- Initial release — Ruby port of [humanizer](https://github.com/christiangenco/humanizer) (Node.js) v2.2.0
- 28 pattern detectors across 5 categories
- 500+ AI vocabulary terms in 3 tiers
- Statistical text analysis (burstiness, TTR, Flesch-Kincaid, trigram repetition)
- Composite scoring engine (0-100)
- CLI with `analyze`, `score`, `humanize`, `suggest`, `stats`, `report` commands
- Humanization engine with auto-fix and suggestion prioritization
- Zero runtime dependencies — pure Ruby
