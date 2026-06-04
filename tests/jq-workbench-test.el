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

(ert-deftest jq-workbench-query-history-test ()
  "Navigate query history with previous and next commands."
  (let ((jq-workbench-query-history nil)
        (query-buffer (generate-new-buffer " *jq-workbench-history-test*")))
    (unwind-protect
        (with-current-buffer query-buffer
          (jq-workbench--add-query-history ".")
          (jq-workbench--add-query-history "select(.ok)")
          (jq-workbench-history-previous)
          (should (string-match-p "select(\\.ok)" (buffer-string)))
          (jq-workbench-history-previous)
          (should (string= ".\n" (buffer-string)))
          (jq-workbench-history-next)
          (should (string-match-p "select(\\.ok)" (buffer-string))))
      (ignore-errors (kill-buffer query-buffer)))))

(ert-deftest jq-workbench-save-load-query-test ()
  "Save and load a named jq query."
  (let ((jq-workbench-query-directory
         (file-name-as-directory (make-temp-file "jq-workbench-query-dir-" t)))
        (query-buffer (generate-new-buffer " *jq-workbench-save-load-test*")))
    (unwind-protect
        (with-current-buffer query-buffer
          (insert "select(.type == \"result\") | {path}\n")
          (jq-workbench-save-query "result-paths")
          (erase-buffer)
          (jq-workbench-load-query "result-paths")
          (should (string-match-p "result" (buffer-string)))
          (should (string-match-p "path" (buffer-string))))
      (ignore-errors (kill-buffer query-buffer))
      (ignore-errors (delete-directory jq-workbench-query-directory t)))))

(ert-deftest jq-workbench-error-line-test ()
  "Extract jq error line numbers from an error buffer."
  (with-temp-buffer
    (insert "jq: error: syntax error at <top-level>, line 12:\n")
    (should (= 12 (jq-workbench--first-error-line)))))

(provide 'jq-workbench-test)

;;; jq-workbench-test.el ends here
