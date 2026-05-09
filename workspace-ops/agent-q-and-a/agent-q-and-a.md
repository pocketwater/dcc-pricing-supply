# Agent Q&A Log — COIL-PRICING-SUPPLY

This file tracks open business questions and semantic clouds surfaced by agents or operators. Answers will be appended inline. Once clarified, resolved semantics will be promoted to the appropriate instructions, ontology, or registry.

---

## Open Questions

1. **What is the full scope of "operational intent"?**
   - What boundaries define an "operational" prompt versus a reporting, analytical, or administrative one?
   - Are there classes of prompts that should never become skills (e.g., ad hoc troubleshooting, one-off data pulls)?

2. **What is the canonical definition of a "blocker" or "anomaly"?**
   - The registry references blockers, anomalies, and "coverage" but does not define them.
   - What are the business rules for what constitutes a blocker, and how are anomalies detected or classified?

3. **What is the lifecycle for a skill after "active"?**
   - The registry says: candidate → active → deprecated.
   - What triggers deprecation? Is there a process for retiring, archiving, or evolving skills as business needs change?

4. **What is the relationship between "human phrases" and "evidence prompts"?**
   - How are generalized human phrases derived from specific evidence prompts?
   - Is there a process for validating that a new prompt is truly a variant of an existing skill?

5. **What is the "execution surface" in practice?**
   - The registry mentions "harness: citysv-gravitate-pdi-ode" and "mode: read_only".
   - What are the possible execution surfaces, and how do they map to real business systems or data sources?

6. **What is the business impact of "reuse_count"?**
   - Is high reuse a signal for automation, or just for documentation?
   - At what point does a skill move from "candidate" to "active" based on reuse, and who decides?

7. **What is the operator's role in skill curation?**
   - The registry says "do not interrupt Jason with registry bookkeeping unless it materially changes the answer".
   - Who is responsible for reviewing, promoting, or cleaning up skills? Is there a governance or review cycle?

8. **How do skills relate to business outcomes?**
   - What business value is created by stabilizing and naming these skills?
   - Is there a feedback loop to measure if a skill, once captured, actually improves operations or decision-making?

---

## Additional Questions From Full Sweep

These surfaced after a deeper read of the full document, with attention not just to skills but to surrounding agent behavior, registry mechanics, and missed primitive opportunities.

9. **What counts as a "non-trivial Jason prompt"?**
   - The working instructions say to evaluate every non-trivial prompt, but the threshold is undefined.
   - Does this mean any prompt requiring business judgment, any prompt touching production concepts, or any prompt that looks reusable?

10. **Who owns projection regeneration and registry hygiene?**
   - The document says Markdown is derived from YAML, but not whether regeneration is manual, scripted, or agent-enforced.
   - If YAML changes without projection refresh, who is responsible for detecting and correcting drift?

11. **What is the decision rule for "materially changes the answer"?**
   - Agents are told not to interrupt Jason with bookkeeping unless it materially changes the answer.
   - What kinds of registry changes are considered material: naming, safety classification, execution surface, promotion, or only answer-shaping semantics?

12. **What is the operational meaning of "closest existing skill"?**
   - When intent is unclear, the document says to append notes to the closest existing skill.
   - What dimensions dominate closeness: domain, verb, inputs, outputs, execution surface, operator wording, or business outcome?

13. **What qualifies as "multiple real evidence prompts"?**
   - Promotion is gated on multiple real prompts or explicit Jason blessing, but the threshold is vague.
   - Is two enough, or is this intentionally judgment-based until a review process exists?

14. **Where should cognitive friction be recorded and reviewed?**
   - The document says to track recurring hesitation like ambiguous date resolution and anomaly detection from vague language.
   - Is there a dedicated artifact for this, and who periodically mines it for guardrails, prompts, or meta-skills?

15. **What counts as an "older artifact describing potential skills"?**
   - Retroactive capture is deferred, but the migration pool is not defined.
   - Does this include runbooks, ad hoc notes, old prompts, script names, agent instructions, or only explicitly skill-like artifacts?

16. **What is the business meaning of the example outputs?**
   - Outputs like `anomaly_flag`, `recommended_next_action`, and `pending_or_failed_count` are suggestive but not canonically defined.
   - Are these diagnostic summaries, operator-facing decisions, workflow routing cues, or future automation fields?

17. **What is the scope boundary between a skill and a meta-skill?**
   - The document explicitly carves out cognitive friction as future meta-skill or guardrail material.
   - What criteria separate an operational skill from a reasoning scaffold, classifier, or coordination primitive?

---

## Candidate Primitive Inclusions

These are not all skills. Several are better represented as prompts, hooks, guardrails, tasks, or agent-level primitives.

1. **Prompt Harvesting Loop**
   - Primitive type: agent workflow.
   - Core shape: observe prompt -> classify reuse -> update canonical registry -> refresh projection.
   - Why it matters: the document is really defining a reusable harvesting protocol, not just a single skill registry.

2. **Source-of-Truth Split**
   - Primitive type: governance rule / content architecture.
   - Core shape: YAML is canonical, Markdown is projection, no competing truths.
   - Better action in hindsight: this could have been captured as a reusable repo primitive for any registry, not only forge skills.

3. **Prompt Classification Triage**
   - Primitive type: classifier prompt or agent hook.
   - Core shape: existing skill match vs new candidate vs one-off.
   - Better action in hindsight: this is a first-class primitive because it governs what happens after every meaningful prompt.

4. **Minimum Definition Gate**
   - Primitive type: validation hook.
   - Core shape: do not create a new entry unless intent, primary inputs, and expected outputs are clear.
   - Better action in hindsight: this should likely exist as a generic primitive-index admission gate, not just prose in one document.

5. **Duplicate Check Gate**
   - Primitive type: review checklist or linter-like hook.
   - Core shape: compare domain, intent, inputs, outputs, execution surface, and safety before creating a new skill.
   - Better action in hindsight: the document already defines a merge heuristic; that is primitive-worthy behavior.

6. **Projection Refresh Hook**
   - Primitive type: task or automation hook.
   - Core shape: YAML change triggers Markdown refresh.
   - Better action in hindsight: if this remains manual, drift will accumulate; this likely wants a script, prompt, or task.

7. **Skill Naming Validator**
   - Primitive type: naming guardrail or lint rule.
   - Core shape: `<Domain>.<verbObject>`, no parameters, no implementation leakage, prefer operator language.
   - Better action in hindsight: this rule is strong enough to be enforceable rather than merely advisory.

8. **Promotion Review Task**
   - Primitive type: periodic review task.
   - Core shape: evaluate candidate skills for promotion, consolidation, or deprecation based on evidence and operator blessing.
   - Better action in hindsight: the lifecycle exists, but the review mechanism does not.

9. **Cognitive Friction Log**
   - Primitive type: meta-skill backlog / agent learning artifact.
   - Core shape: record recurring hesitation, ambiguity, and routing uncertainty.
   - Better action in hindsight: this deserves its own artifact instead of being a buried note inside the registry spec.

10. **Retro-Capture Audit**
   - Primitive type: backlog task or audit pass.
   - Core shape: scan older artifacts for clear reusable intent and migrate only stable skill-like constructs.
   - Better action in hindsight: the document names this work but leaves it structureless; a controlled audit primitive would reduce random migration.

11. **Operator Interruption Threshold**
   - Primitive type: agent policy.
   - Core shape: decide when registry state is answer-relevant enough to surface during normal interaction.
   - Better action in hindsight: this rule is central to user experience and probably belongs in explicit agent behavior canon.

12. **Meta-Skill Boundary Rule**
   - Primitive type: ontology or deontology rule.
   - Core shape: separate operational business skills from reasoning scaffolds, ambiguity handlers, and guardrails.
   - Better action in hindsight: the document hints at this boundary but does not define it, which will matter as the registry grows.

---

## Better-Action Notes In Hindsight

- The document looks like a skill spec on first pass, but on full read it is more importantly a primitive-spec for prompt harvesting and registry governance.
- The strongest missing action was to extract non-skill primitives early: classifier, validator, projection hook, review task, and friction log.
- The biggest semantic clouds are not in the example skill itself; they sit in the verbs that govern agent behavior: `match`, `candidate`, `one-off`, `closest`, `materially`, `multiple`, and `non-trivial`.
- The document implicitly defines a small control plane for agent memory and reuse. That control plane likely belongs in DCC primitives, not just inside a single registry document.

---

*Add answers below each question as they are clarified.*
