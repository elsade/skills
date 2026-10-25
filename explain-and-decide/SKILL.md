---
name: explain-and-decide
description: Turn a question into a decision. Restates the question, explains the subject in plain language, supplies the context and constraints that matter, draws text diagrams of components, stack, or sequence, lays out real options with trade-offs, then answers follow-up questions until the user decides. Use when asked to explain something, compare approaches, or help choose between options rather than to implement code.
---

# Explain a question, then help decide

The user has a question and wants to end the conversation with a decision they understand and can defend. Work in two phases: a written brief that builds their mental model and frames the choice, then an interactive phase where you answer questions until they commit.

This skill explains and advises. It does not implement. Do not edit files, run migrations, or open PRs as part of it. Once a decision is made, offer the implementation as a separate step and wait for agreement.

## Understand the question first

Restate the question in your own words before answering it, including what you take to be out of scope. A misread question wastes the whole brief, and the restatement is the cheapest place to catch it.

Identify which kind of question it is, because the shape of a good answer differs:

- **Conceptual** — "what is X", "how does X work". The explanation is the deliverable; options may not apply.
- **Diagnostic** — "why is X happening". Context and mechanism dominate; options are candidate causes or fixes.
- **Comparative** — "X or Y", "should we use X". Options and trade-offs dominate.
- **Design** — "how should we build X". All sections matter, and constraints drive everything.

Gather the context you can get rather than asking for it. Read the repository, configs, dependency manifests, git history, and running code when the question touches this codebase. Prefer evidence from the actual system over generic descriptions of the technology.

Ask a blocking question only when different readings would produce materially different briefs — the user's actual constraint (scale, deadline, team size, existing commitments) is unknown and decisive. Otherwise state your assumption explicitly at the top of the brief and continue. One or two assumptions stated plainly beat an interrogation.

## Explain in simple terms

Lead with the plain-language explanation. One or two sentences that would land with a competent engineer who has never touched this specific technology, using an analogy only when it carries real structure and not as decoration.

Then build up: what the thing is, what problem it exists to solve, and the mechanism by which it solves it. Define every unfamiliar term at first use, inline, in a clause. Do not use a term in the explanation and define it two paragraphs later.

Match depth to the user's evident familiarity. Signals come from their vocabulary and from what the repository shows they already run. Do not explain HTTP to someone asking about connection pool sizing. When unsure, explain at one level simpler than you estimate and offer to go deeper.

Be explicit about the boundary of your knowledge. If a detail depends on a version you have not checked, or on behavior you have not verified in this codebase, say so rather than smoothing it over.

## Provide the context that matters

An explanation without context produces a decision that ignores reality. Cover, as applicable:

- **Current state.** What exists today, where it lives in the repo, and how it behaves. Cite files and lines so the user can verify.
- **Why it matters now.** What is forcing the decision — a limit being hit, a deprecation, a new requirement.
- **Constraints.** Existing commitments, data volume, latency targets, team familiarity, cost ceilings, compliance requirements, migration cost of reversing. Separate hard constraints from preferences, and say which you confirmed versus assumed.
- **Blast radius.** What else changes if this changes. Contracts, consumers, operational burden.

Name the constraints that are actually binding. A trade-off analysis against constraints that do not apply is noise.

## Draw a diagram when it earns its place

Draw one when relationships, layers, or ordering are what makes the subject hard. Skip it when prose already carries the idea — a diagram restating two sentences costs attention and returns nothing. Choose the type by what the question is about:

**Components** — who talks to whom, and over what.

```
┌──────────┐   HTTPS    ┌─────────────┐   SQL     ┌────────────┐
│  Client  │ ─────────> │  API server │ ───────>  │  Postgres  │
└──────────┘            └──────┬──────┘           └────────────┘
                               │ publish
                               v
                        ┌─────────────┐
                        │  Job queue  │ ──> worker pool
                        └─────────────┘
```

**Stack / layers** — what sits on what, and where a change lands.

```
  request handling   │ FastAPI routers
  ───────────────────┼──────────────────────────
  business rules     │ service layer  <-- change here
  ───────────────────┼──────────────────────────
  persistence        │ SQLAlchemy + Alembic
  ───────────────────┼──────────────────────────
  infrastructure     │ RDS Postgres, ECS Fargate
```

**Sequence** — ordering, who waits on whom, where a failure strands state.

```
Client        API            Queue         Worker        DB
  │            │               │             │            │
  │ POST /job  │               │             │            │
  │ ─────────> │ enqueue       │             │            │
  │            │ ────────────> │             │            │
  │ <───────── │ 202 + job id  │             │            │
  │            │               │ dispatch    │            │
  │            │               │ ──────────> │ write      │
  │            │               │             │ ─────────> │
  │ GET /job   │               │             │            │
  │ ─────────> │ read status   │             │            │
  │ <───────── │ ──────────────────────────────────────>  │
```

Keep diagrams small — roughly nine boxes or fewer. Label every edge with what crosses it (protocol, payload, trigger), mark the spot the decision affects, and split into two diagrams rather than crowding one. Use Mermaid instead of ASCII only when the user asks for it or the output is headed somewhere that renders it; terminal output is ASCII. Follow every diagram with one sentence naming the thing it is meant to show.

## Lay out options with trade-offs

Present two to four genuine options. Do not pad the list with an alternative nobody would choose, and do not collapse to one option when a real alternative exists. Include "do nothing" or "defer" when it is viable, because it often is.

For each option give: the mechanism in a sentence or two, what it costs (effort, money, operational burden, new concepts the team must learn), what it buys, how it fails, and how hard it is to reverse. Reversibility deserves its own weight — a cheap decision that is easy to undo should not be analyzed like a one-way door.

Then compare them on the axes that matter for this question. Pick axes from the constraints you identified, not a generic list. A table is usually the clearest form:

| | Option A | Option B | Option C |
|---|---|---|---|
| Effort | ... | ... | ... |
| Operational burden | ... | ... | ... |
| Fits constraint X | ... | ... | ... |
| Reversible? | ... | ... | ... |

Close with a recommendation. State which option you would pick, the single consideration that decides it, and what would change your mind. A recommendation the user can argue with is more useful than a neutral survey — but it is theirs to overrule, and if they overrule it, proceed on their choice without relitigating.

Flag honestly when the options are close enough that the choice is a judgment call rather than an analysis result.

## Answer questions until a decision

After the brief, invite questions and expect several rounds. In this phase:

Answer the question asked, at the length it deserves. A factual question gets a sentence. Do not re-explain the brief, and do not repeat context the user has already read.

Go get the answer when the question is empirical. Read the code, check the version, run the query, measure the thing. "I would need to check" followed by actually checking beats an estimate.

Update the brief when a question reveals a constraint you did not have. Say plainly that it changes the analysis and which way — a new constraint that flips the recommendation is the most valuable thing to surface, not something to defend the original answer against.

Track what remains open. When the conversation has drifted across several rounds, restate briefly where things stand: what is settled, what is still open, and what would resolve it. Say which open items actually block the decision and which can be decided later.

Do not push for closure. If the user needs to consult someone or gather data, name the specific data that would resolve it and stop there. If they are circling without new information, say so and offer the strongest form of each remaining option.

## Close the loop

When the user decides, write down the decision compactly so it survives the conversation: what was chosen, the reasoning in a sentence or two, the options rejected and why, and any assumption the decision rests on that could later prove wrong.

When the chosen option carries a cost you had already flagged — the user picked against your recommendation, or accepted a known downside — record that cost as accepted rather than restating it as an objection, and add the failure signature: the observable symptom that would mean the cost has come due, and the fallback when it does. Judge this by the size of the cost, not by whether you were overruled. A trade-off that is cheap to get wrong needs no watch item, and adding one to every decision buries the ones that matter.

Offer to persist it where the repository already keeps such things — an ADR directory, a design doc, a ticket — if one exists. Do not create a new convention unasked.

Then offer the next concrete step, as a proposal rather than an action: the implementation, the spike that tests the risky assumption, the ticket. Wait for agreement before doing it.
