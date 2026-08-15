---
name: create-skill
description: "Guide the authoring of a reusable SKILL.md workflow for this workspace."
argument-hint: What workflow or outcome should this skill produce?
disable-model-invocation: true
---

# Create a SKILL.md

Use this skill when you need to capture a multi-step, decision-driven workflow as a reusable workspace skill.

## Workflow

1. Review the conversation and repository context.
   - Identify the task or problem the user is solving.
   - Look for an existing multi-step methodology, checklist, or repeatable process.

2. Extract the workflow structure.
   - Determine the step-by-step actions the user is taking.
   - Capture decision points and branching logic.
   - Note quality criteria, completion checks, or validation steps.

3. Clarify missing details when needed.
   - Ask the user for the desired outcome, if not explicit.
   - Confirm whether the skill should be workspace-scoped or personal.
   - Decide whether the workflow should be a quick checklist or a full multi-stage process.

4. Draft the skill.
   - Choose a clear skill name.
   - Write a concise description and argument hint.
   - Include a structured set of steps and any guardrails.

5. Iterate with the user.
   - Find ambiguous or weak parts of the draft.
   - Ask focused follow-up questions for missing details.
   - Update the skill until it is clear and actionable.

6. Save and validate.
   - Place the skill at `.github/skills/<name>/SKILL.md` for workspace sharing.
   - Verify YAML frontmatter is valid and the description is meaningful.

## When to Use This Skill

- You want to capture a repeatable procedure as a workspace-level skill.
- The task is more than a one-shot prompt and benefits from a structured workflow.
- The workflow includes branching logic, quality checks, or follow-up validation.

## Notes

- If the task is a single focused prompt, use a prompt file instead of a skill.
- If the workflow needs special tool restrictions or strict lifecycle control, consider a custom agent instead.
