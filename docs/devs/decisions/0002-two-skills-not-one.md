# 0002 - Two skills, not one

**Decision:** ship `setup-conventional-commits` and
`pr-conventional-commits` as separate skills rather than one skill
covering both.

## Why

The one-sentence description of a combined skill would have to be
"configure a repository **and** title a pull request". That "and"
joins two different verbs, which is the clearest available signal
that it is two things.

Three independent reasons, any one sufficient:

**Disjoint trigger vocabulary.** Set up, configure, scaffold,
protect versus create, update, title, type. A description covering
both matches neither well, and dispatch quality is the whole game
for a skill.

**Different reasons to change.** One tracks GitHub's settings API,
ruleset schema, and plan limits. The other tracks commit-type
conventions. Those move independently, and a combined skill would
churn for reasons unrelated to half its content.

**Different invocation frequency.** Once per repository versus once
per pull request. This is the expensive one: a combined skill makes
every pull request pay context for repository-administration
content it will never use.

**Different audiences and permissions.** Skill A requires admin.
Skill B is for contributors, who usually do not have it. A combined
skill is mostly unusable by most of the people who need half of it.

## What would make this wrong

If the two halves had to be reassembled at runtime -- if titling a
pull request routinely required configuring the repository first --
the split would be creating work rather than reflecting reality.

It does not. Skill B is useful in a repository that was never
configured, and Skill A is useful to someone who never opens pull
requests themselves. Neither depends on the other at runtime.

## Consequences

Each description must name the other skill as its boundary. That is
not optional politeness; it is what keeps the dispatcher from firing
on the neighbor's territory. See
[0004](0004-skill-b-never-scaffolds.md).

Some content is duplicated between them. That is accepted, and for
the type list it is deliberate --
[0005](0005-duplicate-the-type-list.md).
