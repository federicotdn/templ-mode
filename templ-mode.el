;;; templ-mode.el --- Major mode for editing Templ template files  -*- lexical-binding: t -*-

;; Copyright (C) 2025 Federico Tedin

;; Author: Federico Tedin <federicotedin@gmail.com>
;; Maintainer: Federico Tedin <federicotedin@gmail.com>
;; Homepage: https://github.com/federicotdn/templ-mode
;; Keywords: languages go
;; Package-Version: 1.0.0
;; Package-Requires: ((emacs "30.1") (go-mode "1.6.0"))

;; This file is NOT part of GNU Emacs.

;; templ-mode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; temp-mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with templ-mode.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Major mode for editing Templ template files.
;;
;; This mode provides syntax highlighting for Templ template files,
;; formatting via templ fmt, and LSP support through eglot.

;;; Code:

(defgroup templ-mode nil
  "Major mode for editing Templ template files."
  :prefix "templ-mode-"
  :group 'langauges)

(defcustom templ-mode-command "templ"
  "The command to use for running templ.
If it's a string, use it as the path to the templ binary.
If it's the symbol `tool', `go-command' will be used as Go the binary
to run templ as a Go tool from the root of the current project as
returned by `project-root'."
  :type '(choice (string :tag "path")
                 (const :tag "tool" tool)))

;;;###autoload
(define-derived-mode templ-mode go-mode "Templ"
  "Major mode for editing Templ template files.
This mode extends `go-mode' with additional syntax highlighting for
Templ-specific constructs like templ keywords, @ directives, and
HTML-like tags."
  :group 'templ-mode
  ;; Set up font locking.
  (font-lock-add-keywords
   nil
   `(
     (,(concat "\\(\\s-*templ\\s-+\\)\\(" go-identifier-regexp "\\)")
      (1 font-lock-keyword-face t)
      (2 font-lock-function-name-face t))
     (,(concat "@" go-identifier-regexp) 0 font-lock-negation-char-face t)
     ("<\\([a-zA-Z][a-zA-Z0-9-]*\\)\\([^>]*\\)>\\([^<{}@]*\\)</\\1>"
      (1 font-lock-function-name-face t)
      (2 font-lock-variable-name-face t)
      (3 font-lock-string-face t))
     ("</?\\([a-zA-Z][a-zA-Z0-9-]*\\)\\([^>]*?\\)/?>"
      (1 font-lock-function-name-face t)
      (2 font-lock-variable-name-face t))
     )
   )
  ;; Replace go-mode's handling of indentation.
  (set (make-local-variable 'indent-line-function) #'templ-mode--indent-line)
  ;; Disable electric indentation.
  (when (boundp 'electric-indent-chars)
    (set (make-local-variable 'electric-indent-chars) nil))
  ;; Tweak electric pairs.
  (when (boundp 'electric-pair-pairs)
    (set (make-local-variable 'electric-pair-pairs)
         (cons '(?< . ?>) electric-pair-pairs))))

(defun templ-mode--indent-line ()
  "Indent the current line following a simpler heuristic."
  (let ((current-col (current-column))
        (first-col (save-excursion (back-to-indentation) (current-column)))
        (indentation (current-indentation))
        (prev-indentation (or (ignore-errors
                                (save-excursion
                                  (previous-line)
                                  (current-indentation)))
                              -1)))
    (if (and (< indentation prev-indentation)
             (<= current-col first-col))
        (indent-line-to prev-indentation)
      (insert "\t"))))

(defun templ-fmt ()
  "Format the current buffer using templ fmt."
  (interactive)
  (when (buffer-modified-p)
    (save-buffer))
  (let ((file (buffer-file-name)))
    (unless file
      (user-error "Buffer is not visiting a file"))
    (unless (string-match "\\.templ\\'" file)
      (user-error "Not a .templ file"))
    (let* ((is-tool (eq templ-mode-command 'tool))
           (program (if is-tool go-command templ-mode-command))
           (args (if is-tool
                     (list "tool" "templ" "fmt" file)
                   (list "fmt" file)))
           (proj (and is-tool (project-current)))
           (default-directory (if proj (project-root proj) default-directory))
           (exit-code (apply #'call-process program nil nil nil args)))
      (if (zerop exit-code)
          (progn
            (revert-buffer t t t)
            (message "Applied templ fmt"))
        (user-error "Applying templ fmt failed")))))

(defun templ-mode--server (&rest _)
  "Return the command to start the Templ LSP server."
  (let* ((is-tool (eq templ-mode-command 'tool))
         (proj (and is-tool (project-current)))
         (default-directory (if proj (expand-file-name
                                      (project-root proj))
                              default-directory)))
    (if is-tool
        `("sh" "-c" ,(format "cd %s && %s tool templ lsp"
                             (shell-quote-argument default-directory)
                             go-command))
      (list templ-mode-command "lsp"))))

;;;###autoload
(with-eval-after-load 'eglot
  ;; Add Eglot server command for `templ-mode'.
  (add-to-list 'eglot-server-programs '(templ-mode . templ-mode--server))

  ;; Advice to handle `templ-mode' specially: without this,
  ;; if a `go-mode' Eglot server is already running when the
  ;; user runs 'M-x eglot' on a Templ buffer, the `go-mode'
  ;; server will be used for it, because of how Eglot looks
  ;; up servers for buffers.
  ;;
  ;; NOTE:
  ;; This advice makes assumptions about how the internal
  ;; `eglot--languageId' and `eglot--languages' functions
  ;; work.
  (advice-add 'eglot--languageId :around
              (lambda (orig-fun &rest args)
                ;; For templ-mode buffers specifically...
                (if (eq major-mode 'templ-mode)
                    (let* ((server (car args))
                           (languages (and server (eglot--languages server))))
                      ;; ...check against templ-mode servers exclusively.
                      (cdr (assoc 'templ-mode languages)))
                  (apply orig-fun args)))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.templ\\'" . templ-mode))

(provide 'templ-mode)
;;; templ-mode.el ends here

