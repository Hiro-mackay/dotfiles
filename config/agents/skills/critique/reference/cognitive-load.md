# Cognitive Load Assessment

Humans hold 4 items in working memory at once. Overloaded users make mistakes and leave.

## 8-Item Checklist

Evaluate the interface. Count failures: 0-1 = low (good), 2-3 = moderate, 4+ = critical.

- [ ] **Single focus**: can the user complete primary task without distraction from competing elements?
- [ ] **Chunking**: is information in digestible groups (4 items per group max)?
- [ ] **Grouping**: are related items visually grouped (proximity, borders, shared background)?
- [ ] **Visual hierarchy**: is the most important element immediately clear?
- [ ] **One thing at a time**: can the user focus on a single decision before the next?
- [ ] **Minimal choices**: 4 or fewer visible options at any decision point?
- [ ] **No memory bridges**: does the user need info from a previous screen to act on the current one?
- [ ] **Progressive disclosure**: is complexity revealed only when needed?

## Common Violations

| Violation | Symptom | Fix |
|---|---|---|
| Wall of Options | 10+ choices, no hierarchy | Group, highlight recommended, progressive disclosure |
| Memory Bridge | Must remember step 1 info at step 3 | Keep context visible or repeat where needed |
| Hidden Navigation | Must build mental map | Breadcrumbs, active states, progress indicators |
| Visual Noise Floor | Every element same weight | Clear hierarchy: 1 primary, 2-3 secondary, rest muted |
| Context Switch | Jump between screens for one decision | Co-locate information for each decision |

## Working Memory Limits

- Navigation: 5 top-level items max
- Form sections: 4 fields per visual group
- Action buttons: 1 primary, 1-2 secondary, group rest in menu
- Dashboard: 4 key metrics without scrolling
- Pricing tiers: 3 options max
