# Skill Testing Repos

These are notes related repos used for testing agent skills, and their possible life cycles. Things to keep in mind when considering strategies for testing agent skills.

- Agent skills need to tested in repos outside of the repo they are developed in.

- To test a skill under development, the skill needs to be installed in a test repo where the skill can be tested.

- Test repos may need to be reset or recreated before some tests are run.

- Some tests may require the setup of GitHub repo settings and rulesets.

- Human admin participation in repo setup may be required for some test scenarios.

- Some test repos may be setup and reused, maybe requiring reset operations between test runs. Other test repos may be recreated between test runs.

## Testing GitHub workflows

Fork or clone repos to create repos where GitHub workflows can be developed and tested.

GitHub Actions workflows underdevelopment should be tested in repos separate than the repos they will be ultimatly used in. Many workflows must be run the on the `main` branch. And the run histories of workflows under development can muddy up a repo where other development work is being done.

## A base repo for testing repos

The following repo can be used as the basis for setting up repos for testing the agent skills and workflows under development. The repo can be cloned or forked as needed to create test repos for repeated testing of the skills under development. Otherwise treat it as read-only. No changes should be made to that base repo.

https://github.com/bryanknox/k0x-workbench
