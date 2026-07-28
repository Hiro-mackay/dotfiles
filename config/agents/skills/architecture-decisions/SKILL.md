---
name: architecture-decisions
description: Trade-off analysis, complexity management, reversibility thinking, ADR format, and build-vs-buy decisions. Applies when making architectural choices, evaluating alternatives, assessing whether an abstraction or technology adds justified value, or documenting technical decisions.
---

# Architecture Decision Principles

How to decide and what to write down. General advice about trade-offs existing is deliberately absent.

## Deciding
- Score the options on four axes: complexity, performance, maintainability, operational cost
- Say what you gain and what you give up. Not being able to name the downside means you have not understood the option, and a comparison with no losing column is not a comparison
- Prefer the reversible decision over the optimal one. Being able to change your mind in a month beats being right today
- Ask what it costs to change this in six months. Cheap means decide fast and follow convention -- internal API shape, library choice, folder layout. Expensive means prototype it, get another perspective, and sleep on it -- database engine, public API contract, the data model of anything persisted
- Not deciding is a legitimate decision when the information is not there yet. Design so the component can be swapped, spike to reduce the uncertainty, and choose later
- Put an abstraction at a decision boundary you intend to defer -- and only there. An abstraction everywhere is not flexibility, it is indirection

## Complexity
- Abstraction is only justified when it removes more understanding cost than it adds. Direct code is easier to trace, debug, and change than indirect code
- Wait for the third use case before extracting the pattern. Two is a coincidence
- Do not add parameters for hypothetical callers, or queues, caches, and services without a measured need
- Code that does not exist has no bugs, needs no tests, and cannot drift out of date. Deleting is worth more than adding
- Every dependency is a standing liability. Ask periodically whether you still need each one

## Technology choice
- A team can carry about three novel technologies at once. Spend that budget on the product, not the infrastructure
- Follow the framework's conventions unless you have a measured reason not to
- Build only for a core differentiator or a genuinely unique constraint. Buy when it is a commodity and the operational burden is acceptable. Adopt open source when the community is active and you could maintain it yourself if it were abandoned
- Whatever migration you are estimating, it costs two to three times that

## Writing it down
- ADRs are for significant decisions, not every choice
- Title, Status, Context, Decision, Consequences. Context names the forces and constraints; Decision says what and **why**; Consequences say what got easier and what got harder
- Record the alternatives you rejected and why. That is the part future readers actually need, and the part nobody writes

## Checks before committing
- Could a new team member follow this in fifteen minutes?
- Does the architecture fit on one whiteboard?
- If this component were removed, what would break? If the answer is nothing, remove it
