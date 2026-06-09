# Persona-Based Testing

Select 2-3 personas relevant to the interface. Walk through primary action as each. Report specific red flags per persona.

## Alex — Power User

Expert, expects efficiency, hates hand-holding.

**Red Flags:**
- Forced/unskippable onboarding
- No keyboard shortcuts for primary actions
- No batch/bulk operations where natural
- Slow animations that can't be skipped
- Redundant confirmation for low-risk actions

**Test:** Can core task complete in < 60 seconds? Are there keyboard shortcuts? Can onboarding be skipped?

## Jordan — First-Timer

Never used this type of product. Will abandon rather than figure it out.

**Red Flags:**
- Icon-only navigation without text labels
- Technical jargon without explanation
- No visible help or guidance
- Ambiguous next steps after completing an action
- No confirmation that an action succeeded

**Test:** Is first action clear within 5 seconds? Is there contextual help? Does terminology assume prior knowledge?

## Sam — Accessibility-Dependent

Uses screen reader, keyboard-only. May have low vision or motor impairment.

**Red Flags:**
- Missing focus indicators
- No ARIA labels on interactive elements
- Color as sole information carrier
- Touch targets < 44px
- Layout breaks at 200% zoom

**Test:** Can primary flow complete keyboard-only? Is contrast WCAG AA? Does screen reader announce state changes?

## Casey — Mobile/Low-Bandwidth

Using phone on slow connection. Impatient, one-handed.

**Red Flags:**
- Horizontal scroll on mobile
- Touch targets too close together
- Large unoptimized images
- No offline/error recovery
- Desktop-only features hidden on mobile

**Test:** Does primary action work one-handed? Does it load under 3s on 3G? Are touch targets adequate?

## Morgan — Multilingual/International

Non-native speaker or using translated interface.

**Red Flags:**
- Idioms, slang, or culture-specific references
- Text truncation in UI elements (German +30%)
- Hardcoded date/number formats
- Right-to-left layout issues (if applicable)

**Test:** Would the meaning survive translation? Is there room for text expansion?
