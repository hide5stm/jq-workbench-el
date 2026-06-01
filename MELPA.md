# MELPA Preparation Notes

This repository is prepared for a future MELPA submission, but the actual MELPA
pull request should be opened only after the public GitHub repository URL is
final.

## Files relevant to MELPA

- `jq-workbench.el`: package header, commentary, autoloads, and implementation.
- `jq-workbench-pkg.el`: local package metadata.
- `recipes/jq-workbench`: candidate MELPA recipe.
- `Makefile`: local lint, compile, and test commands.
- `.github/workflows/ci.yml`: GitHub Actions CI.

## Local checks

Run:

```sh
make all
```

This runs:

- byte compilation;
- `checkdoc`;
- `package-lint`;
- ERT tests.

## Candidate recipe

The candidate recipe is in `recipes/jq-workbench`.

Before copying it to a MELPA pull request, replace the repository fetcher details
with the final repository URL if necessary.

## License

The package uses the MIT License, which is GPL-compatible. The package file also
contains an SPDX identifier:

```text
SPDX-License-Identifier: MIT
```

## AI disclosure

MELPA does not currently require Linux-kernel-style AI contribution trailers for
package submission. This project nevertheless includes:

- `AI_POLICY.md`
- `AI_ATTRIBUTION.md`
- `DCO.md`
- a pull request template with AI disclosure checkboxes

The suggested commit trailer for AI-assisted commits is:

```text
Assisted-by: ChatGPT GPT-5.5 Thinking
Signed-off-by: Hideaki Igarashi <hide@5stm.net>
```

The `Signed-off-by` line is a human DCO-style certification and must not be added
by an AI agent.
