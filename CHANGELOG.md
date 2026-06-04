# Changelog

## 0.1.0 - Unreleased

Initial public release candidate.

- Add SQL-mode-like jq workbench layout.
- Add JSON/JSONL input file detection from `buffer-file-name`.
- Add jq query buffer based on `jq-mode` with `prog-mode` fallback.
- Add JSON-highlighted result buffer.
- Add dedicated jq error buffer.
- Add asynchronous jq execution for large inputs.
- Add `jq-workbench-cancel` to cancel a running jq process.
- Add query history navigation with `M-p` and `M-n`.
- Add named query save/load commands.
- Add optional Dired integration via `jq-workbench-dired-mode`.
- Add jq error navigation from the error buffer back to the query buffer.
- Add result font-lock size guard for large outputs.
- Add MELPA preparation files, CI, tests, examples, AI disclosure, and DCO notes.
