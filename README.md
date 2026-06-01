# jq-workbench

`jq-workbench` is a small SQL-mode inspired jq workbench for Emacs.

Open a JSON or JSONL file, write a jq query in the lower query window, and press `C-c C-c` to update the result window.

## Features

- SQL-mode-like split window workflow
- Automatic input file detection from the current JSON/JSONL buffer
- jq query buffer using `jq-mode`
- Result buffer with JSON highlighting where available
- JSONL-friendly filtering with `select(...)`
- Dedicated error buffer for jq syntax/runtime errors
- Small query window, configurable via `jq-workbench-query-window-height`

## Requirements

- Emacs 28.1 or later
- [`jq`](https://jqlang.github.io/jq/)
- [`jq-mode`](https://github.com/ljos/jq-mode)

## Installation

### Manual installation

Clone this repository and add it to your Emacs `load-path`:

```elisp
(add-to-list 'load-path "~/path/to/jq-workbench")
(require 'jq-workbench)
```

Make sure `jq-mode` is also installed and loadable.

### With use-package

```elisp
(use-package jq-workbench
  :load-path "~/path/to/jq-workbench")
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

## Customization

Set the query window height:

```elisp
(setq jq-workbench-query-window-height 5)
```

## Current status

This is an early release intended for simple JSON/JSONL exploration from Emacs.

## License

MIT License. See [LICENSE](LICENSE).
