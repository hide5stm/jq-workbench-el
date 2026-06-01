# Review Checklist

Use this before publishing or opening a future MELPA pull request.

## Repository metadata

- [ ] Repository URL is final.
- [ ] `URL:` header in `jq-workbench.el` is correct.
- [ ] `jq-workbench-pkg.el` metadata is correct.
- [ ] `recipes/jq-workbench` points to the final repository.
- [ ] README installation instructions match the repository URL.

## Package quality

- [ ] `make compile` passes.
- [ ] `make checkdoc` passes.
- [ ] `make package-lint` passes.
- [ ] `make test` passes.
- [ ] `make all` passes.
- [ ] GitHub Actions CI passes.

## Manual smoke test

- [ ] Open `examples/sample.jsonl`.
- [ ] Run `M-x jq-workbench-open`.
- [ ] Confirm the lower query window contains `.`.
- [ ] Press `C-c C-c`.
- [ ] Confirm result buffer updates.
- [ ] Try `examples/sample.jq`.
- [ ] Confirm jq errors appear in `*jq-error*` when entering invalid jq.

## Licensing and contribution process

- [ ] LICENSE is present.
- [ ] SPDX header is present in `jq-workbench.el`.
- [ ] AI policy is present.
- [ ] DCO guidance is present.
- [ ] Initial commit uses appropriate trailers if AI assistance is disclosed.

Suggested initial commit trailer:

```text
Assisted-by: ChatGPT GPT-5.5 Thinking
Signed-off-by: Hideaki Igarashi <hide@5stm.net>
```
