;;; iedit-tests.el --- iedit's automatic-tests

;; Copyright (C) 2010, 2011, 2012 Victor Ren

;; Time-stamp: <2012-03-05 17:25:42 Victor Ren>
;; Author: Victor Ren <victorhge@gmail.com>
;; Version: 0.94
;; X-URL: http://www.emacswiki.org/emacs/Iedit

;; This file is not part of GNU Emacs, but it is distributed under
;; the same terms as GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file is part of iedit.

;;; Code:
(require 'ert)

(ert-deftest iedit-compile-test ()
  (let ((byte-compile-error-on-warn t ))
    (should (byte-compile-file "iedit.el"))
    (delete-file "iedit.elc" nil)))

(defun with-iedit-test-fixture (input-buffer-string body)
  "iedit test fixture"
  (let ((old-transient-mark-mode transient-mark-mode)
        (old-iedit-transient-sensitive iedit-transient-mark-sensitive))
    (unwind-protect
        (progn
          (with-temp-buffer
            (transient-mark-mode t)
            (setq iedit-transient-mark-sensitive t)
            (insert input-buffer-string)
            (goto-char 1)
            (iedit-mode)
            (funcall body))
          (with-temp-buffer
            (setq iedit-transient-mark-sensitive nil)
            (transient-mark-mode -1)
            (insert input-buffer-string)
            (goto-char 1)
            (iedit-mode)
            (funcall body)))
      (transient-mark-mode old-transient-mark-mode)
      (setq iedit-transient-mark-sensitive old-transient-mark-mode))))

(ert-deftest iedit-mode-base-test ()
  (with-iedit-test-fixture
"foo
  foo
   barfoo
   foo"
   (lambda ()
     (should (= 3 (length iedit-occurrences-overlays)))
     (should (string= iedit-initial-string-local "foo"))
     (set-mark-command nil)
     (forward-line 2)
     (iedit-mode)
     (should (= 2 (length iedit-occurrences-overlays)))
     (should (string= iedit-initial-string-local "foo"))
     (iedit-mode)
     (should (null iedit-occurrences-overlays)))))

(ert-deftest iedit-mode-with-region-test ()
  (with-iedit-test-fixture
"foobar
 foo
 foo
 bar
foo"
   (lambda ()
     (iedit-mode)
     (goto-char 1)
     (set-mark-command nil)
     (forward-char 3)
     (iedit-mode)
     (should (= 4 (length iedit-occurrences-overlays)))
     (should (string= iedit-initial-string-local "foo"))
     (should (null iedit-only-complete-symbol-local))
     (goto-char 1)
     (set-mark-command nil)
     (forward-line 3)
     (iedit-mode 4)
     (should (= 1 (length iedit-occurrences-overlays))))))
(ert-deftest iedit-mode-start-from-isearch-test ()
  (with-iedit-test-fixture
"foo
  foo
   barfoo
   foo"
   (lambda ()
     (should (= 3 (length iedit-occurrences-overlays)))
     (should (string= iedit-initial-string-local "foo"))
     (iedit-mode)
     (forward-line 2)
     (isearch-mode t)
     (isearch-process-search-char ?f)
     (isearch-process-search-char ?o)
     (isearch-process-search-char ?o)
     (iedit-mode)
     (should (string= iedit-initial-string-local "foo"))
     (should (= 4 (length iedit-occurrences-overlays)))
     (iedit-mode)
     (should (null iedit-occurrences-overlays)))))

(ert-deftest iedit-mode-last-local-occurrence-test ()
  (with-iedit-test-fixture
"foo
  foo
   barfoo
   foo"
   (lambda ()
     (should (= 3 (length iedit-occurrences-overlays)))
     (should (string= iedit-initial-string-local "foo"))
     (iedit-mode)
     (goto-char 15)
     (iedit-mode 4) ; last local
     (should (string= iedit-initial-string-local "foo"))
     (should (= 3 (length iedit-occurrences-overlays))))))

(ert-deftest iedit-mode-last-global-occurrence-test ()
  (with-iedit-test-fixture
"foo
  foo
   barfoo
   foo"
   (lambda ()
     (should (= 3 (length iedit-occurrences-overlays)))
     (should (string= iedit-initial-string-local "foo"))
     (iedit-mode)
     (with-temp-buffer
       (insert "bar foo foo")
       (goto-char 1)
       (iedit-mode 16)
     (should (string= iedit-initial-string-local "foo"))
     (should (= 2 (length iedit-occurrences-overlays)))))))

(ert-deftest iedit-execute-last-modification-test ()
  (with-iedit-test-fixture
"foo
  foo
   barfoo
   foo"
   (lambda ()
     (should (= 3 (length iedit-occurrences-overlays)))
     (should (string= iedit-initial-string-local "foo"))
     (iedit-mode)
     (with-temp-buffer
       (insert "bar foo foo")
       (should-error (iedit-execute-last-modification))))))

(ert-deftest iedit-movement-test ()
  (with-iedit-test-fixture
"foo
  foo
   barfoo
   foo "
   (lambda ()
     (iedit-last-occurrence)
     (should (= (point) 24))
     (iedit-first-occurrence)
     (should (= (point) 1))
     (iedit-next-occurrence)
     (should (= (point) 7))
     (iedit-next-occurrence)
     (should (= (point) 24))
     (iedit-next-occurrence)
     (should (= (point) 24)) ;; (should (string= (current-message) "This is the last occurrence."))
     (iedit-next-occurrence)
     (should (= (point) 1)) ;; (should (string= (current-message) "Located the first occurrence."))
     (iedit-next-occurrence)
     (should (= (point) 7))
     (goto-char (point-max))
     (iedit-prev-occurrence)
     (should (= (point) 27))
     (iedit-prev-occurrence)
     (should (= (point) 24))
     (iedit-prev-occurrence)
     (should (= (point) 7))
     (iedit-prev-occurrence)
     (should (= (point) 1))
     (iedit-prev-occurrence)
     (should (= (point) 1)) ;; (should (string= (current-message) "This is the first occurrence."))
     (iedit-prev-occurrence)
     (should (= (point) 24)) ;; (should (string= (current-message) "Located the last occurrence."))
     )))

(ert-deftest iedit-occurrence-update-test ()
  (with-iedit-test-fixture
"foo
  foo
   barfoo
   foo"
   (lambda ()
     (insert "1")
     (should (string= (buffer-string)
"1foo
  1foo
   barfoo
   1foo"))
     (backward-delete-char 1)
     (should (string= (buffer-string)
"foo
  foo
   barfoo
   foo"))
     (capitalize-word 1)
     (should (string= (buffer-string)
"Foo
  Foo
   barfoo
   Foo"))
     ;; test insert from empty
     (iedit-delete-occurrences)
     (insert "1")
     (should (string= (buffer-string)
"1
  1
   barfoo
   1")))))

(ert-deftest iedit-toggle-case-sensitive-test ()
  (with-iedit-test-fixture
"foo
  Foo
   barfoo
   foo"
   (lambda ()
     (should (= 2 (length iedit-occurrences-overlays)))
     (iedit-toggle-case-sensitive)
     (should (= 3 (length iedit-occurrences-overlays)))
     (iedit-next-occurrence)
     (iedit-toggle-case-sensitive)
     (should (= 1 (length iedit-occurrences-overlays))))))

(ert-deftest iedit-apply-on-occurrences-test ()
  "Test functions deal with the whole occurrences"
  (with-iedit-test-fixture
"foo
  foo
   barfoo
   foo"
   (lambda ()
     (iedit-upcase-occurrences)
     (should (string= (buffer-string)
"FOO
  FOO
   barfoo
   FOO"))
     (iedit-downcase-occurrences)
     (should (string= (buffer-string)
"foo
  foo
   barfoo
   foo"))
     (iedit-replace-occurrences "bar")
     (should (string= (buffer-string)
"bar
  bar
   barfoo
   bar"))
     (iedit-number-occurrences 1)
     (should (string= (buffer-string)
"1 bar
  2 bar
   barfoo
   3 bar")))))


(ert-deftest iedit-blank-occurrences-test ()
  "Test functions deal with the whole occurrences"
  (with-iedit-test-fixture
"foo foo barfoo foo"
   (lambda ()
     (iedit-blank-occurrences)
     (should (string= (buffer-string) "        barfoo    ")))))

(ert-deftest iedit-delete-occurrences-test ()
  "Test functions deal with the whole occurrences"
  (with-iedit-test-fixture
"foo foo barfoo foo"
   (lambda ()
     (iedit-delete-occurrences)
     (should (string= (buffer-string) "  barfoo ")))))

(ert-deftest iedit-toggle-buffering-test ()
  (with-iedit-test-fixture
"foo
 foo
  barfoo
    foo"
   (lambda ()
     (iedit-toggle-buffering)
     (insert "bar")
     (should (string= (buffer-string)
"barfoo
 foo
  barfoo
    foo"))
     (iedit-toggle-buffering)
     (should (string= (buffer-string)
"barfoo
 barfoo
  barfoo
    barfoo"))
     (should (= (point) 4))
     (iedit-toggle-buffering)
     (backward-delete-char 3)
     (should (string= (buffer-string)
"foo
 barfoo
  barfoo
    barfoo"))
     (goto-char 15) ;not in an occurrence
     (should (null (iedit-find-current-occurrence-overlay)))
     (iedit-toggle-buffering)
     (should (string= (buffer-string)
"foo
 barfoo
  barfoo
    barfoo")))))

(ert-deftest iedit-rectangle-start-test ()
  (with-iedit-test-fixture
"foo
 foo
  barfoo
    foo"
   (lambda ()
   (iedit-mode)
   (set-mark-command nil)
   (forward-char 3)
   (forward-line 3)
   (iedit-rectangle-mode)
   (should (equal iedit-rectangle '(1 19))))))

(ert-deftest iedit-kill-rectangle-error-test ()
  (with-iedit-test-fixture
"foo
 foo
  barfoo
    foo"
   (lambda ()
   (iedit-mode)
   (set-mark-command nil)
   (goto-char 22)
   (iedit-rectangle-mode)
   (should (iedit-same-column))
   (should (equal iedit-rectangle '(1 22)))
   (iedit-prev-occurrence)
   (delete-char -1)
   (should (not (iedit-same-column)))
   (should-error (iedit-kill-rectangle)))))

(ert-deftest iedit-kill-rectangle-test ()
  (with-iedit-test-fixture
"foo
 foo
  barfoo
    foo"
   (lambda ()
   (iedit-mode)
   (set-mark-command nil)
   (goto-char 22)
   (iedit-rectangle-mode)
   (should (iedit-same-column))
   (should (equal iedit-rectangle '(1 22)))
   (iedit-kill-rectangle)
   (should (string= (buffer-string)
"
o
arfoo
 foo"))
 (should (equal killed-rectangle '("foo" " fo" "  b" "   "))))))

(ert-deftest iedit-restrict-defun-test ()
  (with-iedit-test-fixture
"a
(defun foo (foo bar foo)
\"foo bar foobar\" nil)
(defun bar (bar foo bar)
  \"bar foo barfoo\" nil)"
   (lambda ()
      (iedit-mode)
      (emacs-lisp-mode)
      (goto-char 5)
      (iedit-mode)
      (iedit-restrict-function)
      (should (= 1 (length iedit-occurrences-overlays)))
      (iedit-mode)
      (goto-char 13)
      (iedit-mode-on-function)
      (should (= 4 (length iedit-occurrences-overlays)))
      (iedit-mode)
      (iedit-mode)
      (mark-defun)
      (iedit-mode)
      (should (= 4 (length iedit-occurrences-overlays))))))

(ert-deftest iedit-transient-sensitive-test ()
  (with-iedit-test-fixture
"a
(defun foo (foo bar foo)
\"foo bar foobar\" nil)
(defun bar (bar foo bar)
  \"bar foo barfoo\" nil)"
   (lambda ()
      (iedit-mode)
      (emacs-lisp-mode)
      (setq iedit-transient-mark-sensitive t)
      (transient-mark-mode -1)
      (goto-char 5)
      (iedit-mode)
      (iedit-restrict-function)
      (should (= 1 (length iedit-occurrences-overlays)))
      (iedit-mode)
      (goto-char 13)
      (iedit-mode 0)
      (should (= 4 (length iedit-occurrences-overlays)))
      (iedit-mode)
      (iedit-mode)
      (mark-defun)
      (iedit-mode)
      (should (= 0 (length iedit-occurrences-overlays))))))

(defvar iedit-printable-test-lists
  '(("" "")
    ("abc" "abc")
    ("abc
bcd" "abc...")
    ("abc\n34" "abc...")
    ("12345678901234567890123456789012345678901234567890abc" "12345678901234567890123456789012345678901234567890...")
    ("12345678901234567890123456789012345678901234567890abc
abcd" "12345678901234567890123456789012345678901234567890...")))

(ert-deftest iedit-printable-test ()
  (dolist (test iedit-printable-test-lists)
    (should (string= (iedit-printable (car test)) (cadr test)))))


;; (elp-instrument-list '(insert-and-inherit
;;                        delete-region
;;                        goto-char
;;                        iedit-occurrence-update
;;                        buffer-substring-no-properties
;;                        string=
;;                        re-search-forward
;;                        replace-match))


;;; iedit-tests.el ends here
