;;; jq-workbench-test.el --- Tests for jq-workbench -*- lexical-binding: t; -*-

(require 'ert)
(require 'jq-workbench)

(ert-deftest jq-workbench-input-file-from-current-buffer-test ()
  "Return the current file as an expanded file name."
  (let ((file (make-temp-file "jq-workbench-test-" nil ".jsonl")))
    (unwind-protect
        (with-current-buffer (find-file-noselect file)
          (should (equal (expand-file-name file)
                         (jq-workbench--input-file-from-current-buffer))))
      (ignore-errors (kill-buffer (find-buffer-visiting file)))
      (ignore-errors (delete-file file)))))

(ert-deftest jq-workbench-run-basic-query-test ()
  "Run a basic jq query against a temporary JSONL file."
  (skip-unless (executable-find jq-workbench-command))
  (let ((file (make-temp-file "jq-workbench-test-" nil ".jsonl"))
        (query-buffer (generate-new-buffer " *jq-workbench-test-query*"))
        (result-buffer (generate-new-buffer " *jq-workbench-test-result*")))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert "{\"type\":\"result\",\"path\":\"a.mp4\",\"score\":\"0.9\"}\n")
            (insert "{\"type\":\"other\",\"path\":\"b.mp4\",\"score\":\"0.1\"}\n"))
          (with-current-buffer query-buffer
            (insert "select(.type == \"result\") | {path, score}\n")
            (setq-local jq-workbench-input-file file)
            (setq-local jq-workbench-result-buffer result-buffer)
            (jq-workbench-run))
          (with-current-buffer result-buffer
            (should (string-match-p "a\\.mp4" (buffer-string)))
            (should-not (string-match-p "b\\.mp4" (buffer-string)))))
      (ignore-errors (kill-buffer query-buffer))
      (ignore-errors (kill-buffer result-buffer))
      (ignore-errors (delete-file file)))))

(provide 'jq-workbench-test)

;;; jq-workbench-test.el ends here
