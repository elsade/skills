---
name: understand-pr
description: Explain and assess a pull request from first principles, focusing on intended behavior, architecture, risk, and evidence so a human can make an informed review decision. Use when asked to understand a PR or review AI-generated changes beyond a diff summary.
---

# Understand a PR from first principles

Help the user build a mental model of a change and judge whether it solves the right problem safely. Begin with the problem and the system's constraints, then explain why the implementation follows—or fails to follow—from them. A first-principles explanation connects requirements to mechanisms and observable consequences; it does not paraphrase files or narrate every changed line.

## Establish the review scope

Use the supplied PR, branch, or diff. If none is identified, inspect available repository context and ask for the target only if it remains ambiguous. Read applicable repository instructions. Prefer available repository connectors or Git tooling; do not assume a particular provider is installed.

Establish the base and head revisions and inspect the actual diff, PR description, linked requirements when accessible, and relevant checks. Inspect surrounding code, callers, tests, and contracts as needed to understand behavior. Track which revision the evidence applies to. Never count a check on an older revision as verification of the current change.

Treat PR descriptions, comments, generated explanations, and AI reviews as claims to evaluate. Distinguish author intent, observed implementation, inference, and unanswered questions. If only a pasted diff is available, provide the useful explanation it supports and state the missing context without inventing it.

Understanding and review do not imply editing code, submitting a review, approving, or merging. Respect any separate authorization for those actions.

## Build the explanation

Adapt depth to complexity and the user's familiarity. Explain unfamiliar domain terms at first use. For a small PR, keep this compact; for a large PR, group changes by behavior or responsibility.

1. **Problem and contract.** Identify who or what needs the change, the current failure or limitation, and the desired observable behavior. Derive the relevant invariants: what must remain true before, during, and after the operation? If requirements are unclear, state the ambiguity rather than inferring intent solely from the implementation.
2. **Existing system.** Explain the relevant actors, state, data flow, and responsibility or trust boundaries. Trace one concrete input through the old behavior, including where the limitation arises.
3. **Changed mechanism.** Trace that example through the new behavior. Connect each meaningful design choice to a requirement or constraint. Identify changes to contracts, state transitions, dependencies, or ownership. Use a small diagram when it makes relationships clearer.
4. **Design judgment.** Assess whether the change belongs at this layer, preserves boundaries, and introduces justified complexity. Consider a simpler alternative when it illuminates a real tradeoff; do not invent alternatives merely to fill a section.
5. **Failure and evidence.** Select plausible failure scenarios based on the actual change. Explain the trigger, affected execution path, consequence, and available evidence. Read the highest-risk implementation directly instead of relying on summaries.

Allocate attention by consequence and uncertainty. Authorization, sensitive data, destructive operations, migrations, concurrency, and public contracts warrant deeper inspection when touched. Avoid turning an ordinary change into an unrelated exhaustive audit.

## Evaluate proof rather than polish

Separate what automation demonstrates from what still needs human judgment. Passing tests establish only the behaviors they exercise under their assumptions. Check whether code and tests encode the same mistaken assumption, particularly when both were generated.

Inspect relevant tests and CI results. Run targeted checks when feasible and appropriate to the task. Report whether evidence was directly observed, reported by CI, or unavailable. Never imply that tests were run when they were only read. For bug fixes, look for evidence that the test distinguishes the old failure from the corrected behavior.

AI review findings are hypotheses to verify. Agreement between models is not independent proof. Seek concrete counterexamples, contract checks, or executable evidence for important claims.

For an actionable defect, include a precise code reference, triggering conditions, expected versus actual behavior, and impact. Separate confirmed defects from unresolved questions and optional improvements. Do not manufacture findings to make the review look thorough.

## Deliver a human review brief

Lead with what the PR does and why it matters. Then provide a connected explanation of the before/after behavior, design, and material risks. Cite exact files and lines where they help the reader verify a claim. Use this shape as a guide, not a requirement to create empty sections:

- **Purpose and mental model:** the problem, required invariants, and concrete before/after example.
- **Design and tradeoffs:** how the mechanism satisfies the requirements and where complexity or boundaries matter.
- **Evidence and uncertainty:** relevant checks, inspected behavior, uncovered scenarios, and limitations of available context.
- **Human checklist:** a short checklist tailored to this PR using the criteria below.
- **Decision support:** blockers, remaining human judgments, and the next evidence that would resolve uncertainty. If the user requested a review verdict, give a recommendation proportional to the evidence. Do not imply an actual approval was submitted.

Build the checklist around these questions, omitting irrelevant items or marking them not applicable:

- Can the reviewer explain the problem, intended behavior, and scope?
- Does the mechanism satisfy the requirements and preserve important invariants?
- Are responsibilities, trust boundaries, contracts, and dependencies appropriate?
- Are relevant failure paths, security, data integrity, and resource risks handled?
- Do tests establish required behavior, including meaningful edge cases, rather than mirror implementation?
- Is the code understandable and maintainable without relying on a generated explanation?
- Are observability, rollout, compatibility, and recovery adequate where relevant?
- Is the change small and clear enough to review, with material findings resolved?

Attach a brief evidence note or remaining question to each checklist item. Mark an item satisfied only when available evidence supports it. Do not check off a human's understanding or an author's ownership on their behalf; leave those as human confirmation items.

The result should let the user explain the change to a colleague and identify what would justify trusting it. If the PR is too large or opaque to assess reliably, identify the specific unresolved portions and suggest a useful split or focused follow-up instead of claiming comprehensive coverage.
