---
name: naming-and-modeling
description: Naming as a design tool, ubiquitous language, and domain modeling heuristics. Applies when modeling a business domain, designing module/service boundaries, or diagnosing design problems through naming friction.
---

# Naming & Modeling Principles

## Naming as Design Signal
- A name that's hard to find = a concept that's poorly defined in the design
- If you can't name it clearly, you don't understand it yet. Stop and clarify before coding
- Name change resistance ("but we've always called it X") signals design debt
- When a name needs a comment to explain it, the name is wrong
- Renaming is the safest refactoring and often the most valuable

## Naming Reveals Problems
- A class with "And" in the name does two things: split it
- A function named `processData` hides its actual purpose: name what it does specifically
- A variable named `temp`, `data`, `result`, `info` carries no meaning: name the content
- A boolean named `flag` or `status` is ambiguous: name the condition (`isExpired`, `hasPermission`)
- A module named `utils`, `helpers`, `common` is a grab bag: distribute to where things belong

## Ubiquitous Language (from DDD)
- Code, documentation, and conversation MUST use the same terms for the same concepts
- If the domain expert says "order", the code says `Order` -- not `Purchase`, `Transaction`, or `Request`
- Different bounded contexts MAY use different names for similar concepts -- that's correct, not inconsistent
- When domain experts disagree on terminology, that signals a boundary between contexts
- Glossary: maintain a shared vocabulary for the domain. Code IS the executable glossary

## Naming Conventions
- Nouns for entities and values: `User`, `Invoice`, `Temperature`
- Verbs for actions and commands: `sendEmail`, `calculateTotal`, `cancelOrder`
- Adjectives/past participles for states: `isActive`, `wasProcessed`, `hasFailed`
- Prepositions for transformations: `toJSON`, `fromDTO`, `asReadOnly`
- Collections: plural nouns (`users`, `pendingOrders`). Never `userList` or `userData`
- Abbreviations: only universally understood ones (`id`, `url`, `http`). Spell out domain terms

## Metaphor Awareness
- Metaphors shape thinking: "pipeline" implies linear flow, "tree" implies hierarchy
- Choose metaphors that match the domain's actual structure
- Bad metaphor = wrong mental model = wrong design decisions
- Watch for metaphor mismatch: if your "queue" allows random access, it's not a queue
- Resist extending metaphors beyond their useful range ("the factory's factory's builder")

## Modeling Heuristics
- Model what the system DOES, not what the real world IS. Software models are purpose-built
- Start with behaviors (what happens), not structures (what exists). Verbs before nouns
- If two concepts have different lifecycles, they're different entities
- If two concepts always change together, they might be one entity
- Time is almost always relevant: "when did this happen?" should be answerable
- State machines: if an entity has distinct phases with different rules, model it as explicit states
- Avoid god entities: if `User` has 30 fields, it's modeling multiple concepts

## Anti-patterns
- **Naming by implementation**: `HashMap`, `LinkedList` in domain code -- name by purpose, not structure
- **Encoding type in name**: `strName`, `iCount` (Hungarian notation) -- the type system handles this
- **Negation in names**: `isNotValid`, `disableAutoSave` -- double negatives cause bugs. Use positive form
- **Generic suffixes**: `Manager`, `Handler`, `Processor`, `Service` -- these words mean nothing. Name the responsibility
- **Acronym overload**: internal acronyms are onboarding barriers. Spell out for public interfaces
