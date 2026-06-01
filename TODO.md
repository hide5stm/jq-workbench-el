# TODO

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

- [ ] Dired integration: open jq workbench for file at point.
- [ ] Query history with `M-p` / `M-n`.
- [ ] Optional auto-run after idle delay.
- [ ] Save and load named jq queries.
- [ ] Result export command.
- [ ] Better support for raw output modes such as `@tsv` and `@csv`.
- [ ] Optional three-pane layout: source JSON, jq query, result.
- [ ] jq error navigation.
