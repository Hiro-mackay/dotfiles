---
name: naming-conventions
description: Naming as a design tool covering naming signals, problem detection through names, conventions, metaphor awareness, and anti-patterns. Applies when naming variables, functions, modules, or services, or when diagnosing design problems through naming friction.
---

# Naming Conventions

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

## Conventions
- Nouns for entities and values: `User`, `Invoice`, `Temperature`
- Verbs for actions and commands: `sendEmail`, `calculateTotal`, `cancelOrder`
- Adjectives/past participles for states: `isActive`, `wasProcessed`, `hasFailed`
- Prepositions for transformations: `toJSON`, `fromDTO`, `asReadOnly`
- Collections: plural nouns (`users`, `pendingOrders`). Never `userList` or `userData`
- Abbreviations: only universally understood ones (`id`, `url`, `http`). Spell out domain terms

## Metaphor Awareness
- A borrowed word imports its structure: "pipeline" promises linear flow, "tree" promises hierarchy. Readers will design against that promise, so a mismatch produces wrong decisions, not just an odd name. If your "queue" allows random access, it is not a queue
- Do not extend a metaphor past where it still explains anything ("the factory's factory's builder")

## Anti-patterns
- **Naming by implementation**: `HashMap`, `LinkedList` in domain code -- name by purpose, not structure
- **Encoding type in name**: `strName`, `iCount` (Hungarian notation) -- the type system handles this
- **Negation in names**: `isNotValid`, `disableAutoSave` -- double negatives cause bugs. Use positive form
- **Generic suffixes**: `Manager`, `Handler`, `Processor`, `Service` -- these words mean nothing. Name the responsibility
- **Acronym overload**: internal acronyms are onboarding barriers. Spell out for public interfaces
