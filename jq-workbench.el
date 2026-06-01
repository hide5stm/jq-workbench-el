;;; jq-workbench.el --- SQL-style jq workbench for JSON/JSONL -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Hideaki Igarashi

;; Author: Hideaki Igarashi <hide@5stm.net>
;; Maintainer: Hideaki Igarashi <hide@5stm.net>
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: tools, convenience
;; URL: https://github.com/hideaki-igarashi/jq-workbench
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; jq-workbench provides a SQL-mode inspired workflow for jq.
;;
;; Open a JSON or JSONL file, run `jq-workbench-open', edit a jq query
;; in the lower window, and press \[jq-workbench-run] to update the result
;; buffer.  The package is intentionally small: it uses `jq-mode' for query
;; highlighting when available and delegates jq execution to the external jq
;; command.

;;; Code:

(require 'subr-x)

(defgroup jq-workbench nil
  "SQL-mode-like jq workbench."
  :group 'tools
  :prefix "jq-workbench-")

(defcustom jq-workbench-command "jq"
  "Name or path of the jq executable."
  :type 'string
  :group 'jq-workbench)

(defcustom jq-workbench-query-window-height 5
  "Height of the jq query window created by `jq-workbench-open'."
  :type 'integer
  :safe #'integerp
  :group 'jq-workbench)

(defvar-local jq-workbench-input-file nil
  "Input JSON or JSONL file for the current jq workbench buffer.")

(defvar-local jq-workbench-result-buffer nil
  "Result buffer associated with the current jq workbench query buffer.")

(defun jq-workbench--input-file-from-current-buffer ()
  "Return the current buffer file name as an expanded path.

Return nil when the current buffer is not visiting a file."
  (when buffer-file-name
    (expand-file-name buffer-file-name)))

(defun jq-workbench--ensure-jq ()
  "Return the jq executable path or signal a user error."
  (or (executable-find jq-workbench-command)
      (user-error "Could not find jq executable: %s" jq-workbench-command)))


(defun jq-workbench--query-mode ()
  "Enable a jq-oriented major mode for the query buffer.

Use `jq-mode' when it is installed.  Fall back to `prog-mode' so the
package can still byte-compile and run without optional query
highlighting support."
  (if (require 'jq-mode nil t)
      (jq-mode)
    (prog-mode)))

(defun jq-workbench--result-mode ()
  "Enable a JSON-oriented major mode for a jq result buffer."
  (cond
   ((fboundp 'json-ts-mode) (json-ts-mode))
   ((fboundp 'js-json-mode) (js-json-mode))
   ((fboundp 'json-mode) (json-mode))
   (t (fundamental-mode)))
  (setq-local truncate-lines nil)
  (when (fboundp 'font-lock-ensure)
    (font-lock-ensure)))

;;;###autoload
(defun jq-workbench-set-input-file (file)
  "Set input JSON or JSONL FILE for the current jq query buffer."
  (interactive "fInput JSON/JSONL file: ")
  (setq-local jq-workbench-input-file (expand-file-name file))
  (message "jq input: %s" jq-workbench-input-file))

;;;###autoload
(defun jq-workbench-run ()
  "Run the current jq query against `jq-workbench-input-file'."
  (interactive)
  (unless jq-workbench-input-file
    (call-interactively #'jq-workbench-set-input-file))
  (let* ((jq-command (jq-workbench--ensure-jq))
         (input-file (expand-file-name jq-workbench-input-file))
         (query (string-trim-right
                 (buffer-substring-no-properties (point-min) (point-max))))
         (query-file (make-temp-file "jq-workbench-" nil ".jq"))
         (error-file (make-temp-file "jq-workbench-error-"))
         (result-buffer (or jq-workbench-result-buffer
                            (get-buffer-create "*jq-result*")))
         (error-buffer (get-buffer-create "*jq-error*")))
    (unless (file-exists-p input-file)
      (user-error "Input file does not exist: %s" input-file))
    (when (string-empty-p query)
      (user-error "jq query is empty"))
    (with-temp-file query-file
      (insert query)
      (insert "\n"))
    (with-current-buffer result-buffer
      (let ((inhibit-read-only t))
        (erase-buffer)))
    (with-current-buffer error-buffer
      (let ((inhibit-read-only t))
        (erase-buffer)))
    (unwind-protect
        (let ((status
               (call-process jq-command
                             nil
                             `(,result-buffer ,error-file)
                             nil
                             "-f" query-file
                             input-file)))
          (if (= status 0)
              (progn
                (with-current-buffer result-buffer
                  (jq-workbench--result-mode))
                (display-buffer result-buffer))
            (with-current-buffer error-buffer
              (insert-file-contents error-file)
              (special-mode))
            (display-buffer error-buffer)))
      (ignore-errors (delete-file query-file))
      (ignore-errors (delete-file error-file)))))

;;;###autoload
(define-minor-mode jq-workbench-mode
  "Minor mode for SQL-mode-like jq execution."
  :lighter " jq-wb"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-c") #'jq-workbench-run)
            (define-key map (kbd "C-c C-f") #'jq-workbench-set-input-file)
            map))

;;;###autoload
(defun jq-workbench-open (&optional file)
  "Open a SQL-mode-like jq workbench for FILE.

When called interactively from a file-visiting buffer, use that file as
input.  If the current buffer is not visiting a file, prompt for an input
file.  When called from Lisp with FILE, use FILE instead."
  (interactive)
  (let* ((input-file
          (expand-file-name
           (or file
               (jq-workbench--input-file-from-current-buffer)
               (read-file-name "Input JSON/JSONL file: "))))
         (base-name (file-name-nondirectory input-file))
         (result-buffer (get-buffer-create
                         (format "*jq-result: %s*" base-name)))
         (query-buffer (get-buffer-create
                        (format "*jq-query: %s*" base-name))))
    (unless (file-exists-p input-file)
      (user-error "Input file does not exist: %s" input-file))
    (delete-other-windows)
    ;; Upper window: result.
    (switch-to-buffer result-buffer)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (format "Input: %s\n\n" input-file)))
    (jq-workbench--result-mode)
    ;; Lower window: query.  Keep it small, like SQL mode.
    (let* ((total-height (window-total-height))
           (query-height (min jq-workbench-query-window-height
                              (max 3 (/ total-height 3))))
           (result-height (max 1 (- total-height query-height))))
      (split-window-vertically result-height))
    (other-window 1)
    (switch-to-buffer query-buffer)
    (jq-workbench--query-mode)
    (jq-workbench-mode 1)
    (setq-local jq-workbench-input-file input-file)
    (setq-local jq-workbench-result-buffer result-buffer)
    (when (= (point-min) (point-max))
      (insert ".\n"))
    (message "jq input: %s" input-file)))

(provide 'jq-workbench)

;;; jq-workbench.el ends here
