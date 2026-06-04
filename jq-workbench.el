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
(declare-function dired-get-file-for-visit "dired" ())

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

(defcustom jq-workbench-query-history-limit 100
  "Maximum number of jq queries kept in query history."
  :type 'integer
  :safe #'integerp
  :group 'jq-workbench)

(defcustom jq-workbench-query-directory
  (locate-user-emacs-file "jq-workbench/queries/")
  "Directory used by `jq-workbench-save-query' and `jq-workbench-load-query'."
  :type 'directory
  :group 'jq-workbench)

(defcustom jq-workbench-result-font-lock-max-bytes 1048576
  "Maximum result buffer size for immediate font-locking.

Large jq outputs can be expensive to fontify.  When the result buffer is
larger than this value, jq-workbench still selects a JSON-oriented major
mode but skips immediate `font-lock-ensure'.  Set this to nil to always
fontify result buffers."
  :type '(choice (const :tag "Always fontify" nil)
                 integer)
  :safe (lambda (value) (or (null value) (integerp value)))
  :group 'jq-workbench)

(defvar jq-workbench-query-history nil
  "History list of jq queries run in jq-workbench buffers.")

(defvar-local jq-workbench-input-file nil
  "Input JSON or JSONL file for the current jq workbench buffer.")

(defvar-local jq-workbench-result-buffer nil
  "Result buffer associated with the current jq workbench query buffer.")

(defvar-local jq-workbench-error-buffer nil
  "Error buffer associated with the current jq workbench query buffer.")

(defvar-local jq-workbench--process nil
  "Running jq process associated with the current jq workbench query buffer.")

(defvar-local jq-workbench--query-file nil
  "Temporary jq query file associated with the current jq process.")

(defvar-local jq-workbench--history-index nil
  "Current index into `jq-workbench-query-history' for this query buffer.")

(defvar-local jq-workbench--query-buffer nil
  "Query buffer associated with the current jq error buffer.")

(defun jq-workbench--input-file-from-current-buffer ()
  "Return the current buffer file name as an expanded path.

Return nil when the current buffer is not visiting a file."
  (when buffer-file-name
    (expand-file-name buffer-file-name)))

(defun jq-workbench--ensure-jq ()
  "Return the jq executable path or signal a user error."
  (or (executable-find jq-workbench-command)
      (user-error "Could not find jq executable: %s" jq-workbench-command)))

(declare-function jq-mode "jq-mode" ())
(defun jq-workbench--query-mode ()
  "Enable a jq-oriented major mode for the query buffer.

Use `jq-mode' when it is installed.  Fall back to `prog-mode' so the
package can still byte-compile and run without optional query
highlighting support."
  (if (require 'jq-mode nil t)
      (jq-mode)
    (prog-mode)))

(defun jq-workbench--try-major-mode (mode)
  "Enable major MODE and return non-nil when it succeeds.

Some modes, notably `json-ts-mode' on Emacs 29+, may be defined even
when the required tree-sitter grammar is not installed.  In that case,
MODE signals an error and jq-workbench should fall back to another JSON
mode instead of failing the jq run."
  (when (fboundp mode)
    (condition-case nil
        (progn
          (funcall mode)
          t)
      (error nil))))

(defun jq-workbench--result-mode ()
  "Enable a JSON-oriented major mode for a jq result buffer."
  (or (jq-workbench--try-major-mode 'json-ts-mode)
      (jq-workbench--try-major-mode 'js-json-mode)
      (jq-workbench--try-major-mode 'json-mode)
      (fundamental-mode))
  (setq-local truncate-lines nil)
  (when (and (fboundp 'font-lock-ensure)
             (or (null jq-workbench-result-font-lock-max-bytes)
                 (<= (buffer-size) jq-workbench-result-font-lock-max-bytes)))
    (font-lock-ensure)))

(defun jq-workbench--buffer-query ()
  "Return the current buffer contents as a jq query string."
  (string-trim-right
   (buffer-substring-no-properties (point-min) (point-max))))

(defun jq-workbench--replace-query (query)
  "Replace the current query buffer contents with QUERY."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert query)
    (unless (or (string-empty-p query) (string-suffix-p "\n" query))
      (insert "\n"))))

(defun jq-workbench--add-query-history (query)
  "Add QUERY to `jq-workbench-query-history'."
  (unless (string-empty-p query)
    (setq jq-workbench-query-history
          (cons query (delete query jq-workbench-query-history)))
    (when (> (length jq-workbench-query-history) jq-workbench-query-history-limit)
      (setcdr (nthcdr (1- jq-workbench-query-history-limit)
                      jq-workbench-query-history)
              nil))))

(defun jq-workbench-history-previous ()
  "Replace the current query with the previous jq query history item."
  (interactive)
  (unless jq-workbench-query-history
    (user-error "jq query history is empty"))
  (setq jq-workbench--history-index
        (min (1- (length jq-workbench-query-history))
             (1+ (or jq-workbench--history-index -1))))
  (jq-workbench--replace-query
   (nth jq-workbench--history-index jq-workbench-query-history)))

(defun jq-workbench-history-next ()
  "Replace the current query with the next jq query history item."
  (interactive)
  (unless jq-workbench-query-history
    (user-error "jq query history is empty"))
  (setq jq-workbench--history-index
        (max 0 (1- (or jq-workbench--history-index 0))))
  (jq-workbench--replace-query
   (nth jq-workbench--history-index jq-workbench-query-history)))

(defun jq-workbench--cleanup-process (process)
  "Clean up temporary files associated with PROCESS."
  (let ((query-file (process-get process 'jq-workbench-query-file)))
    (when query-file
      (ignore-errors (delete-file query-file)))))

(defun jq-workbench--process-sentinel (process event)
  "Handle jq PROCESS status changes described by EVENT."
  (when (memq (process-status process) '(exit signal))
    (jq-workbench--cleanup-process process)
    (let ((query-buffer (process-get process 'jq-workbench-query-buffer))
          (result-buffer (process-get process 'jq-workbench-result-buffer))
          (error-buffer (process-get process 'jq-workbench-error-buffer))
          (exit-status (process-exit-status process)))
      (when (buffer-live-p query-buffer)
        (with-current-buffer query-buffer
          (when (eq jq-workbench--process process)
            (setq jq-workbench--process nil
                  jq-workbench--query-file nil))))
      (cond
       ((process-get process 'jq-workbench-cancelled)
        (message "jq cancelled"))
       ((and (eq (process-status process) 'exit) (= exit-status 0))
        (when (buffer-live-p result-buffer)
          (with-current-buffer result-buffer
            (jq-workbench--result-mode))
          (display-buffer result-buffer))
        (message "jq finished"))
       ((string-match-p "finished" event)
        (message "jq finished"))
       (t
        (when (buffer-live-p error-buffer)
          (with-current-buffer error-buffer
            (goto-char (point-max))
            (unless (bolp)
              (insert "\n"))
            (insert (format "jq process %s" event))
            (special-mode)
            (setq-local jq-workbench--query-buffer query-buffer)
            (local-set-key (kbd "RET") #'jq-workbench-goto-error)
            (local-set-key (kbd "g") #'jq-workbench-goto-error))
          (display-buffer error-buffer))
        (message "jq failed: %s" (string-trim-right event)))))))

(defun jq-workbench--execute-query (jq-command query input-file result-buffer error-buffer query-buffer)
  "Run JQ-COMMAND asynchronously with QUERY against INPUT-FILE.

Write standard output to RESULT-BUFFER and standard error to
ERROR-BUFFER.  QUERY-BUFFER is used for process bookkeeping and jq error
navigation.  Return the started process."
  (let ((query-file (make-temp-file "jq-workbench-" nil ".jq")))
    (with-temp-file query-file
      (insert query)
      (insert "\n"))
    (with-current-buffer result-buffer
      (let ((inhibit-read-only t))
        (setq buffer-read-only nil)
        (erase-buffer)))
    (with-current-buffer error-buffer
      (let ((inhibit-read-only t))
        (setq buffer-read-only nil)
        (erase-buffer)))
    (let ((process
           (make-process
            :name "jq-workbench"
            :buffer result-buffer
            :command (list jq-command "-f" query-file input-file)
            :stderr error-buffer
            :noquery t
            :sentinel #'jq-workbench--process-sentinel)))
      (process-put process 'jq-workbench-query-file query-file)
      (process-put process 'jq-workbench-query-buffer query-buffer)
      (process-put process 'jq-workbench-result-buffer result-buffer)
      (process-put process 'jq-workbench-error-buffer error-buffer)
      (with-current-buffer query-buffer
        (setq-local jq-workbench--process process
                    jq-workbench--query-file query-file))
      process)))

(defun jq-workbench-running-p ()
  "Return non-nil when a jq process is running for the current query buffer."
  (and jq-workbench--process
       (process-live-p jq-workbench--process)))

;;;###autoload
(defun jq-workbench-cancel ()
  "Cancel the running jq process for the current query buffer."
  (interactive)
  (unless (jq-workbench-running-p)
    (user-error "No jq process is running"))
  (process-put jq-workbench--process 'jq-workbench-cancelled t)
  (delete-process jq-workbench--process)
  (message "jq cancelled"))

;;;###autoload
(defun jq-workbench-set-input-file (file)
  "Set input JSON or JSONL FILE for the current jq query buffer."
  (interactive "fInput JSON/JSONL file: ")
  (setq-local jq-workbench-input-file (expand-file-name file))
  (message "jq input: %s" jq-workbench-input-file))

;;;###autoload
(defun jq-workbench-run ()
  "Run the current jq query asynchronously against `jq-workbench-input-file'."
  (interactive)
  (unless jq-workbench-input-file
    (call-interactively #'jq-workbench-set-input-file))
  (let* ((jq-command (jq-workbench--ensure-jq))
         (input-file (expand-file-name jq-workbench-input-file))
         (query (jq-workbench--buffer-query))
         (result-buffer (or jq-workbench-result-buffer
                            (get-buffer-create "*jq-result*")))
         (error-buffer (or jq-workbench-error-buffer
                           (get-buffer-create "*jq-error*")))
         (query-buffer (current-buffer)))
    (unless (file-exists-p input-file)
      (user-error "Input file does not exist: %s" input-file))
    (when (string-empty-p query)
      (user-error "jq query is empty"))
    (when (jq-workbench-running-p)
      (delete-process jq-workbench--process))
    (jq-workbench--add-query-history query)
    (setq jq-workbench--history-index nil)
    (with-current-buffer error-buffer
      (setq-local jq-workbench--query-buffer query-buffer))
    (jq-workbench--execute-query jq-command
                                 query
                                 input-file
                                 result-buffer
                                 error-buffer
                                 query-buffer)
    (message "jq started: %s" input-file)))

(defun jq-workbench--current-query-buffer ()
  "Return the query buffer associated with the current buffer."
  (cond
   ((bound-and-true-p jq-workbench-mode) (current-buffer))
   ((and (boundp 'jq-workbench--query-buffer)
         (buffer-live-p jq-workbench--query-buffer))
    jq-workbench--query-buffer)
   (t nil)))

(defun jq-workbench--first-error-line ()
  "Return the first jq error line number in the current buffer, or nil."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "[Ll]ine[[:space:]]+\\([0-9]+\\)" nil t)
      (string-to-number (match-string 1)))))

;;;###autoload
(defun jq-workbench-goto-error ()
  "Jump from a jq error buffer to the corresponding line in the query buffer."
  (interactive)
  (let ((line (jq-workbench--first-error-line))
        (query-buffer jq-workbench--query-buffer))
    (unless line
      (user-error "Could not find a jq error line number"))
    (unless (buffer-live-p query-buffer)
      (user-error "No live jq query buffer is associated with this error buffer"))
    (pop-to-buffer query-buffer)
    (goto-char (point-min))
    (forward-line (1- line))))

(defun jq-workbench--query-file-name (name)
  "Return the query file name for saved query NAME."
  (expand-file-name (concat (file-name-base name) ".jq")
                    jq-workbench-query-directory))

(defun jq-workbench--saved-query-names ()
  "Return saved jq query names without the .jq suffix."
  (when (file-directory-p jq-workbench-query-directory)
    (mapcar #'file-name-base
            (directory-files jq-workbench-query-directory nil "\\.jq\\'"))))

;;;###autoload
(defun jq-workbench-save-query (name)
  "Save the current jq query as NAME under `jq-workbench-query-directory'."
  (interactive
   (list (read-string "Save jq query as: ")))
  (let ((query (jq-workbench--buffer-query)))
    (when (string-empty-p query)
      (user-error "jq query is empty"))
    (make-directory jq-workbench-query-directory t)
    (with-temp-file (jq-workbench--query-file-name name)
      (insert query)
      (insert "\n"))
    (message "Saved jq query: %s" name)))

;;;###autoload
(defun jq-workbench-load-query (name)
  "Load saved jq query NAME into the current query buffer."
  (interactive
   (list (completing-read "Load jq query: "
                          (jq-workbench--saved-query-names)
                          nil t)))
  (let ((file (jq-workbench--query-file-name name)))
    (unless (file-exists-p file)
      (user-error "Saved jq query does not exist: %s" name))
    (jq-workbench--replace-query
     (with-temp-buffer
       (insert-file-contents file)
       (string-trim-right (buffer-string))))
    (message "Loaded jq query: %s" name)))

;;;###autoload
(define-minor-mode jq-workbench-mode
  "Minor mode for SQL-mode-like jq execution."
  :lighter " jq-wb"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-c") #'jq-workbench-run)
            (define-key map (kbd "C-c C-f") #'jq-workbench-set-input-file)
            (define-key map (kbd "C-c C-k") #'jq-workbench-cancel)
            (define-key map (kbd "C-c C-s") #'jq-workbench-save-query)
            (define-key map (kbd "C-c C-l") #'jq-workbench-load-query)
            (define-key map (kbd "M-p") #'jq-workbench-history-previous)
            (define-key map (kbd "M-n") #'jq-workbench-history-next)
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
         (error-buffer (get-buffer-create
                        (format "*jq-error: %s*" base-name)))
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
    (setq-local jq-workbench-error-buffer error-buffer)
    (with-current-buffer error-buffer
      (setq-local jq-workbench--query-buffer query-buffer))
    (when (= (point-min) (point-max))
      (insert ".\n"))
    (message "jq input: %s" input-file)))

(defvar jq-workbench-dired-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "W") #'jq-workbench-dired-open)
    map)
  "Keymap used by `jq-workbench-dired-mode'.")

;;;###autoload
(define-minor-mode jq-workbench-dired-mode
  "Minor mode adding jq-workbench commands to Dired buffers."
  :lighter " jq-wb"
  :keymap jq-workbench-dired-mode-map
  (unless (derived-mode-p 'dired-mode)
    (jq-workbench-dired-mode -1)
    (user-error "`jq-workbench-dired-mode' is intended for Dired buffers")))

;;;###autoload
(defun jq-workbench-dired-open ()
  "Open `jq-workbench' for the file at point in Dired."
  (interactive)
  (unless (derived-mode-p 'dired-mode)
    (user-error "This command is intended for Dired buffers"))
  (jq-workbench-open (dired-get-file-for-visit)))

(provide 'jq-workbench)

;;; jq-workbench.el ends here
