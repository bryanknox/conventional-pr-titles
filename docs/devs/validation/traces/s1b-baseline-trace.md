# s1b baseline trace — conventional commits + squash merges setup

Repo: bryanknox/k0x-test-cc-s1b. Date: 2026-07-28. All commands run from the local clone
`...\scratchpad\k0x-test-cc-s1b` unless noted. File reads via the Read tool are omitted;
file creations/edits are listed inline where they occurred in sequence.

## Ordered command log

1. `git status && git remote -v && git log --oneline -5 && ls -la`
   — Clean tree on `main`; remotes: `origin`=k0x-test-cc-s1b, `base`=k0x-workbench (untouched).
2. `find .github docs .claude -type f`
   — Enumerated existing workflows (`ci-checks.yml`, `ci-workflow-pwsh.yml`, `vtag-release.yml`), pwsh module + Pester test, dependabot.yml, docs.
3. `gh repo view bryanknox/k0x-test-cc-s1b --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed,deleteBranchOnMerge,defaultBranchRef`
   — All three merge methods allowed; `deleteBranchOnMerge=false`; default branch `main`.
4. `gh api repos/bryanknox/k0x-test-cc-s1b --jq '{merge settings}'` + `gh api .../rulesets` + `gh api .../branches/main/protection`
   — Baseline: `squash_merge_commit_title=COMMIT_OR_PR_TITLE`, `squash_merge_commit_message=COMMIT_MESSAGES`; no rulesets; branch not protected (HTTP 404).
5. (Write) Created `.github/workflows/pwsh/Test-PrTitleOrExit.psm1` — OrExit-pattern validator per `ai/gh-workflow-pwsh-orexit-guidelines.md`.
6. (Write) Created `.github/workflows/pwsh-unit-tests/Test-PrTitleOrExit.Tests.ps1` — Pester 5 tests mirroring existing test style.
7. (Write) Created `.github/workflows/pr-title-check.yml` — pull_request [opened, edited, reopened, synchronize]; checkout pinned to same SHA as other workflows; title passed via env var to avoid script injection.
8. (Write/Edit) Created `docs/conventional-commits.md` and `.github/PULL_REQUEST_TEMPLATE.md`; linked doc from `README.md` (Development docs list) and `AGENTS.md` (new Conventions subsection).
9. `Invoke-Pester -Path "Test-PrTitleOrExit.Tests.ps1" -Output Detailed` (pwsh, in `.github/workflows/pwsh-unit-tests`)
   — 11/11 tests passed (Pester 5.7.1).
10. `Invoke-Pester -Path .` (all workflow pwsh tests)
    — 20/20 tests passed (existing Get-AssemblyNameOrExit tests unaffected).
11. `gh api -X PATCH repos/bryanknox/k0x-test-cc-s1b -f allow_squash_merge=true -f allow_merge_commit=false -f allow_rebase_merge=false -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY -f delete_branch_on_merge=true`
    — Confirmed response: squash-only, PR_TITLE/PR_BODY, delete_branch_on_merge=true.
12. `git add <workflow+module+tests> && git commit -m "ci: add pr-title-check workflow enforcing Conventional Commit PR titles"`
    — Commit `f83d2f3`, 3 files, +388.
13. `git add <docs+template+README+AGENTS> && git commit -m "docs: document Conventional Commits and squash-merge policy"`
    — Commit `77fc64a`, 4 files, +104.
14. `git push origin main`
    — Pushed `11f4547..77fc64a`.
15. `gh run list --repo bryanknox/k0x-test-cc-s1b --limit 5`
    — "CI PowerShell Workflow" queued for the push (run 30396962722).
16. `gh run watch 30396962722 --exit-status` then `gh run view`
    — Completed success; `test-powershell-scripts` job green in 25s.
17. `git checkout -b test/pr-title-check-verify && printf '<temp line>' >> docs/conventional-commits.md && git commit -am "temp: verification change (PR will be closed unmerged)" && git push -u origin test/pr-title-check-verify`
    — Test branch pushed (`18815a2`); docs-only change so no heavy CI triggered.
18. `gh pr create --head test/pr-title-check-verify --title "Testing the pr title check" --body ...`
    — PR #2 created with intentionally invalid title.
19. Poll `gh pr checks 2` (loop, 10s interval)
    — "Check PR Title" **fail** in 10s (run 30397062238) — invalid title correctly rejected.
20. `gh pr edit 2 --title "test(workflows): verify pr-title-check workflow"` then poll `gh pr checks 2`
    — New run on `edited` event; "Check PR Title" **pass** in 10s (run 30397099449).
21. `gh pr close 2 --delete-branch --comment ...` then `git checkout main && git branch -D test/pr-title-check-verify`
    — PR #2 closed unmerged; remote + local test branch deleted; clone back on clean `main`.
22. (Read) `.github/dependabot.yml`
    — Already emits conventional PR titles (`ci(deps):`, `build(deps):`); no change needed.

## Final state

- origin/main: `77fc64a` (docs) on top of `f83d2f3` (ci), both conventional commits.
- Repo settings: squash merge only; squash title = PR title; squash body = PR body; head branches auto-deleted.
- `pr-title-check` verified live: fails bad titles, passes good ones.
- Not done (deliberate): branch protection / required checks (owner pushes directly to main), local commit-msg hooks/commitlint (branch commits are squashed away), no changes to `base` remote or any other repo.
