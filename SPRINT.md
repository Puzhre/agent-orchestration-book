# Book Iteration SPRINT

## Current Status
- Core chapters 1-15 exist (EN + ZH)
- Quality uneven: ch04 (423 lines, good depth) vs ch09 (138 lines, shallow)
- Research repos analyzed but insights not fully extracted
- BOOK_QUALITY_RULES.md v1 established (graduation: 92, dim>=8, evidence>=9)

## In Progress
- Score all 15 chapters against quality standard to establish baseline

## Queue
1. Strengthen weakest chapters first (lowest scores):
   - ch09 Prompt Engineering (138 lines, likely shallow)
   - ch13 Antipatterns (153 lines, needs real failure cases)
   - ch01 Introduction (209 lines, may lack depth)
2. Extract deep insights from research repos (Overstory mail system, Composio worktree, agency-agents pipeline)
3. Crawl new sources: LangGraph, OpenAI Agents SDK, CrewAI, AutoGen — compare patterns
4. Add cross-project comparison tables to every Part I chapter
5. Add runnable code examples to every Part II chapter
6. Strengthen Part III with real production failure cases and evolution data
7. Ensure every chapter has Key Insights summary section
8. Chinese translations quality audit (must match EN, no degradation)
9. Add new chapters if needed (e.g., "Security & Sandboxing", "Cost Control", "Observability")
10. Terminal build test: mkdocs build must pass clean

## Done
- Core chapters 1-15 drafted
- Source repos cloned and analyzed
- Cross-project comparison for ch04 Communication
- BOOK_QUALITY_RULES.md v1 written
- Crawl automation set up (scripts/crawl.sh)
