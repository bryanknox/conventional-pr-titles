# 0008 - Maintainer material stays outside the skill folders

**Decision:** evals, test procedures, validation records, planning
documents, and contributor documentation live outside `skills/`.
Only what a skill needs at runtime goes in its folder.

## Why

**It would all ship.** A skill folder is copied whole into a
consumer's repository. Anything inside it travels to every user, for
no benefit to them.

**Context cost.** Material in a skill folder is material the model
may load. Test procedures and planning documents are pure overhead
on every invocation.

**Dispatch contamination.** This is the subtle one. Eval files are
full of example prompts -- deliberately including prompts that
*should not* trigger the skill. Putting text like that inside a
skill folder risks it being treated as part of what the skill is
for. The near-miss prompts are the worst possible thing to have
sitting next to a description whose entire job is matching prompts.

## The rule

Ask: does the skill read this at runtime, in a user's repository?

- **Yes** -- inside the folder. The workflow template Skill A
  installs; the type guide Skill B reads when a classification is
  ambiguous.
- **No** -- outside. Everything else.

There is no middle category. Documentation *about* a skill lives in
`docs/`, even when it is describing that exact skill.

## Consequences

Some duplication between a skill body and the documentation about
it. That is correct -- they have different audiences and different
lifecycles, and the version in the skill is constrained by context
cost in a way the documentation is not.

The evals directory needs its own explanation of what it is testing,
since it cannot rely on sitting next to the thing it tests.
