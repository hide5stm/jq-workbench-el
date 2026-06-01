# TODO

## High priority

- Add jq query history (`M-p` / `M-n` style navigation).
- Add command to save the current jq query to a `.jq` file.
- Add command to load a `.jq` file into the query buffer.
- Add Dired integration: open `jq-workbench` for the file at point.
- Add basic tests for command construction and file detection.

## Medium priority

- Optional auto-run after query edit with debounce.
- Optional auto-run after saving a query buffer.
- Add result export commands:
  - save raw result
  - save TSV/CSV result
- Improve result mode selection for non-JSON outputs such as `@tsv` and `@csv`.
- Add support for multiple workbench sessions without buffer-name collisions.

## Low priority

- MELPA packaging cleanup.
- Screenshot/GIF demo for README.
- Add transient/hydra-style command menu.
- Add jq cheat sheet commands for common JSONL filters.
- Add ERT tests in CI.
