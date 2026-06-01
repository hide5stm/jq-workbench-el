EMACS ?= emacs
BATCH = $(EMACS) -Q --batch
PACKAGE_USER_DIR = $(CURDIR)/.elpa
PACKAGE_SETUP = --eval "(setq package-user-dir \"$(PACKAGE_USER_DIR)\")"
PACKAGE_INIT = $(PACKAGE_SETUP) -l package --eval "(package-initialize)"
LISP = jq-workbench.el
TESTS = tests/jq-workbench-test.el
DEPS = package-lint

.PHONY: all compile test checkdoc package-lint lint clean install-deps check-trailers

all: lint test

install-deps:
	$(BATCH) $(PACKAGE_SETUP) -l package --eval "(progn (add-to-list 'package-archives '(\"melpa\" . \"https://melpa.org/packages/\") t) (package-initialize) (unless package-archive-contents (package-refresh-contents)) (dolist (pkg '($(DEPS))) (unless (package-installed-p pkg) (package-install pkg))))"

compile: install-deps
	$(BATCH) -L . $(PACKAGE_INIT) -f batch-byte-compile $(LISP)

test: install-deps
	$(BATCH) -L . $(PACKAGE_INIT) -l $(TESTS) -f ert-run-tests-batch-and-exit

checkdoc: install-deps
	$(BATCH) -L . $(PACKAGE_INIT) --eval "(progn (require 'checkdoc) (find-file \"$(LISP)\") (checkdoc-current-buffer t))"

package-lint: install-deps
	$(BATCH) -L . $(PACKAGE_INIT) --eval "(progn (require 'package-lint) (package-lint-batch-and-exit))" $(LISP)

lint: compile checkdoc package-lint

check-trailers:
	./scripts/check-commit-trailers.sh HEAD

clean:
	rm -f *.elc

clean-deps:
	rm -rf .elpa
