# Contributing

Thank you for considering a contribution to `jq-workbench`.

## Development prerequisites

Install:

- Emacs 28.1 or later
- jq
- GNU make

The Makefile installs Emacs Lisp development dependencies from MELPA into the
batch Emacs package directory when needed.

## Local checks

Before submitting a change, run:

```sh
make all
```

This currently runs:

- byte compilation;
- `checkdoc`;
- `package-lint`;
- ERT tests.

You can also run individual targets:

```sh
make compile
make checkdoc
make package-lint
make test
```

## Commit sign-off

This project uses a DCO-style convention. Please sign commits with:

```sh
git commit -s
```

This adds a human certification trailer:

```text
Signed-off-by: Your Name <you@example.com>
```

## AI-assisted changes

AI-assisted changes are allowed when they are reviewed and accepted by a human
maintainer or contributor. AI tools must not add the `Signed-off-by` trailer.

When AI materially assisted a commit, add an `Assisted-by` trailer before the
human `Signed-off-by` trailer:

```text
Assisted-by: ChatGPT GPT-5.5 Thinking
Signed-off-by: Your Name <you@example.com>
```

See [AI_POLICY.md](AI_POLICY.md), [AI_ATTRIBUTION.md](AI_ATTRIBUTION.md), and
[DCO.md](DCO.md).

## MELPA readiness

This repository is prepared for a future MELPA submission. Before opening a PR to
`melpa/melpa`, verify that:

- the repository URL in `jq-workbench.el`, `jq-workbench-pkg.el`, and
  `recipes/jq-workbench` points to the final public GitHub repository;
- `make all` passes on a clean checkout;
- the MELPA recipe builds with `package-build`;
- the package license remains GPL-compatible.
