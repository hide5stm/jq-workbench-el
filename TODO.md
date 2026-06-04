# TODO

This file tracks remaining work only. Completed user-facing features are
recorded in `CHANGELOG.md`.

## Before public GitHub release

- [ ] Replace placeholder repository URLs in:
  - `jq-workbench.el`
  - `jq-workbench-pkg.el`
  - `recipes/jq-workbench`
- [ ] Run `make all` on a clean checkout.
- [ ] Confirm GitHub Actions passes after pushing.
- [ ] Add screenshots to `docs/screenshots/` and reference them from `README.md`.
- [ ] Create the initial signed commit:

  ```text
  Assisted-by: ChatGPT GPT-5.5 Thinking
  Signed-off-by: Hideaki Igarashi <hide@5stm.net>
  ```

## Before MELPA pull request

- [ ] Confirm the public repository URL is final.
- [ ] Confirm `package-lint` passes without warnings.
- [ ] Confirm `checkdoc` passes without warnings.
- [ ] Confirm byte compilation passes on Emacs 28.1+.
- [ ] Confirm ERT tests pass.
- [ ] Build with MELPA `package-build` locally.
- [ ] Verify the recipe in `recipes/jq-workbench` against MELPA conventions.
- [ ] Decide whether to keep the standalone `jq-workbench-pkg.el` file.
- [ ] Tag the first release, for example `v0.1.0`.

## Future features

### Responsiveness and large inputs

- [ ] Streaming/progress UI for very large outputs.
- [ ] Optional auto-run after idle delay.
- [ ] Result size controls, for example truncation, paging, or line limits.

### Output modes and export

- [ ] Result export command.
- [ ] Better support for raw output modes such as `@tsv` and `@csv`.
- [ ] jq option presets, for example `-r`, `-c`, `-s`, and `--arg`.

### Workspace layout

- [ ] Optional three-pane layout: source JSON, jq query, result.
- [ ] Command to switch the input JSON/JSONL file without reopening the workbench.

### Query management

- [ ] Query library browser for saved named queries.
- [ ] Per-project or per-input-file query history.
