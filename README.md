# jq-workbench

[![CI](https://github.com/hide5stm/jq-workbench-el/actions/workflows/ci.yml/badge.svg)](https://github.com/hide5stm/jq-workbench-el/actions/workflows/ci.yml)

`jq-workbench` is a small SQL-mode inspired jq workbench for Emacs.

Open a JSON or JSONL file, write a jq query in the lower query window, and press
`C-c C-c` to update the result window asynchronously.

## Features

- SQL-mode-like split window workflow
- Automatic input file detection from the current JSON/JSONL buffer
- jq query buffer using `jq-mode` when available
- Result buffer with JSON highlighting where available
- JSONL-friendly filtering with `select(...)`
- Asynchronous jq execution, so large inputs do not block Emacs while jq is running
- Dedicated error buffer for jq syntax/runtime errors
- Query history with `M-p` / `M-n`
- Named jq query save/load commands
- Optional Dired integration via `jq-workbench-dired-mode`
- Small query window, configurable via `jq-workbench-query-window-height`

## Requirements

- Emacs 28.1 or later
- [`jq`](https://jqlang.github.io/jq/)
- [`jq-mode`](https://github.com/ljos/jq-mode) is optional but recommended for jq query highlighting

## Installation

### Manual installation

Clone this repository and add it to your Emacs `load-path`:

```elisp
(add-to-list 'load-path "~/path/to/jq-workbench")
(require 'jq-workbench)
```

For jq query highlighting, install `jq-mode` separately. `jq-workbench` still works without it, but the query buffer falls back to `prog-mode`.

### With use-package

```elisp
(use-package jq-workbench
  :load-path "~/path/to/jq-workbench"
  :hook (dired-mode . jq-workbench-dired-mode))
```

## Usage

Open a JSON or JSONL file, for example:

```text
examples/sample.jsonl
```

Then run:

```text
M-x jq-workbench-open
```

The window is split into:

```text
+----------------------------+
| jq result buffer           |
|                            |
+----------------------------+
| jq query buffer            |
| .                          |
+----------------------------+
```

Press:

```text
C-c C-c
```

The default query is:

```jq
.
```

which prints the input as-is.

## Examples

Show only records with `type == "result"`:

```jq
select(.type == "result")
```

Show only selected fields:

```jq
select(.type == "result")
| {path, score}
```

Filter by numeric score when `score` is stored as a string:

```jq
select(.type == "result" and (.score | tonumber) >= 0.8)
| {path, score, action}
```

Create TSV-style output:

```jq
select(.type == "result")
| [.path, .score, .action]
| @tsv
```

## Key bindings

Inside `jq-workbench-mode`:

| Key | Command | Description |
| --- | --- | --- |
| `C-c C-c` | `jq-workbench-run` | Run the current jq query |
| `C-c C-f` | `jq-workbench-set-input-file` | Select another input JSON/JSONL file |
| `C-c C-k` | `jq-workbench-cancel` | Cancel the running jq process |
| `C-c C-s` | `jq-workbench-save-query` | Save the current jq query by name |
| `C-c C-l` | `jq-workbench-load-query` | Load a named jq query |
| `M-p` | `jq-workbench-history-previous` | Insert the previous query from history |
| `M-n` | `jq-workbench-history-next` | Insert the next query from history |

Inside Dired, enable `jq-workbench-dired-mode` and press `W` on a file to open it in jq-workbench.

## Customization

Set the query window height:

```elisp
(setq jq-workbench-query-window-height 5)
```

Set the jq executable path:

```elisp
(setq jq-workbench-command "/usr/bin/jq")
```

Skip immediate font-locking for large result buffers.  The default is 1 MiB:

```elisp
(setq jq-workbench-result-font-lock-max-bytes 1048576)
```

Set it to nil to always fontify jq results:

```elisp
(setq jq-workbench-result-font-lock-max-bytes nil)
```

## Development

Run the local checks used before MELPA submission:

```sh
make all
```

The GitHub Actions workflow runs byte compilation, `checkdoc`, `package-lint`,
and ERT tests on Emacs 28.2 and 29.4.

## AI-assisted development disclosure

This project may contain code, documentation, tests, or project scaffolding
prepared with AI assistance. All AI-assisted changes must be reviewed and
accepted by a human maintainer.

For the initial scaffold:

```text
Assisted-by: ChatGPT GPT-5.5 Thinking
Signed-off-by: Hideaki Igarashi <hide@5stm.net>
```

See [AI_POLICY.md](AI_POLICY.md), [AI_ATTRIBUTION.md](AI_ATTRIBUTION.md), and
[DCO.md](DCO.md).

## MELPA preparation

This repository is structured so that a future MELPA submission can add the
recipe in `recipes/jq-workbench` to the `melpa/melpa` repository.

Before opening a MELPA pull request, verify:

- the project URL in `jq-workbench.el`, `jq-workbench-pkg.el`, and
  `recipes/jq-workbench` matches the final GitHub repository;
- the package byte-compiles cleanly;
- `package-lint` reports no issues;
- `checkdoc` reports no documentation issues;
- the package builds and installs using MELPA's package-build workflow;
- the license remains GPL-compatible.

## Current status

This is an early release intended for simple JSON/JSONL exploration from Emacs.

## License

MIT License. See [LICENSE](LICENSE).
