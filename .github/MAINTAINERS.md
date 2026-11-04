# Repository maintenance

- **Admin / approver:** [@somayaj](https://github.com/somayaj) — required reviewer on all PRs to `main` (see `CODEOWNERS` + branch protection)
- **Default branch:** `main` — pull requests only; at least one approval from a code owner
- **Commit messages:** `feat:`, `fix:`, `docs:`, `chore:`, `refactor:` (see `.cursor/rules/commit-messages.mdc`)

## Approvals

Branch protection requires **code owner review**. `@somayaj` is the code owner for the whole repo.

GitHub does not let you approve your own pull request. If you open a PR yourself, either ask another GitHub user to approve, or (as repo admin with bypass enabled) merge using admin privileges when appropriate.
