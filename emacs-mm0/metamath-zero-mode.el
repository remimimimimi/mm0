;;; metamath-zero-mode.el --- Emacs mode for Metamath Zero -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 remimimimimi
;;
;; Author: remimimimimi <remimimimimi@protonmail.com>
;; Maintainer: remimimimimi <remimimimimi@protonmail.com>
;; Created: marraskuu 07, 2022
;; Modified: marraskuu 07, 2022
;; Version: 0.0.1
;; Keywords: convenience languages lisp tools
;; Homepage: https://github.com/digama0/mm0/tree/master/emacs-mm0
;; Package-Requires: ((emacs "24.4"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Emacs mode for Metamath Zero specification language
;;
;;; Code:

(require 'generic-x)

;; TODO: add support for identifiers prefixed by `:'
(define-generic-mode 'metamath-zero-mode
  '("--")
  '("lassoc" "rassoc" "abstract" "local"
    "axiom" "coercion" "do" "def"
    "delimiter" "free" "infixl" "infixr"
    "if" "fn" "let" "letrec" "begin"
    "focus" "set-merge-strategy" "match"
    "input" "max" "notation" "output"
    "prec" "prefix" "provable" "pub"
    "pure" "import" "sort" "strict"
    "term" "exit" "theorem")
  '(("--|" . font-lock-doc-face))
  '(".mm[01]")
  (list
   (lambda () ;; Configure autopairs
     (setq metamath-zero-mode-map (make-sparse-keymap))
     (define-key metamath-zero-mode-map "(" 'electric-pair)
     (define-key metamath-zero-mode-map "[" 'electric-pair)
     (define-key metamath-zero-mode-map "{" 'electric-pair)
     (define-key metamath-zero-mode-map "$" 'electric-pair)))
  "A mode for metamath zero (mm0) files")

(with-eval-after-load 'lsp-mode
  (defcustom-lsp lsp-metamath-zero-executable-path "mm0-rs"
    "Path to the MM0 server."
    :type 'string
    :group 'lsp-metamath-zero
    :package-version '(lsp-mode . "8.0.1")
    :lsp-path "metamath-zero.executablePath")

  (defcustom-lsp lsp-metamath-zero-warn-unnecessary-parens-enable nil
    "Give warning on unnecessary parens."
    :type 'bool
    :group 'lsp-metamath-zero
    :package-version '(lsp-mode . "8.0.1"))

  (defcustom-lsp lsp-metamath-zero-max-number-of-problems 100
    "Controls the maximum number of problems produced by the server."
    :type 'number
    :group 'lsp-metamath-zero
    :package-version '(lsp-mode . "8.0.1")
    :lsp-path "metamath-zero.maxNumberOfProblems")

  (defcustom-lsp lsp-metamath-zero-trace-server "off"
    "Traces the communication between VS Code and the language server."
    :type '(choice (:tag off messages verbose))
    :group 'lsp-metamath-zero
    :package-version '(lsp-mode . "8.0.1")
    :lsp-path "metamath-zero.trace.server")

  (defcustom-lsp lsp-metamath-zero-elab-on "change"
    "Set the server to elaborate changes either on every change/keystroke, or on save."
    :type '(choice (:tag change save))
    :group 'lsp-metamath-zero
    :package-version '(lsp-mode . "8.0.1")
    :lsp-path "metamath-zero.elabOn")

  (defcustom-lsp lsp-metamath-zero-syntax-docs t
    "If true (the default), the server will show syntax documentation on hover."
    :type 'boolean
    :group 'lsp-metamath-zero
    :package-version '(lsp-mode . "8.0.1")
    :lsp-path "metamath-zero.syntaxDocs")

  (defcustom-lsp lsp-metamath-zero-log-errors t
    "If true (the default), errors will also be sent to the 'output' panel."
    :type 'boolean
    :group 'lsp-metamath-zero
    :package-version '(lsp-mode . "8.0.1")
    :lsp-path "metamath-zero.logErrors")

  (defcustom-lsp lsp-metamath-zero-report-upstream-errors t
    "If true (the default), errors in imported files will be reported on the \
'import' command (in addition to the files themselves)."
    :type 'boolean
    :group 'lsp-metamath-zero
    :package-version '(lsp-mode . "8.0.1")
    :lsp-path "metamath-zero.reportUpstreamErrors")

  ;; Register lsp server.
  (add-to-list 'lsp-language-id-configuration
    '(metamath-zero-mode . "metamath-zero"))
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection "mm0-rs server")
    ;; :new-connection (lsp-stdio-connection
    ;;                   (lambda ()
    ;;                     (append `,(list lsp-metamath-zero-executable-path "server")
    ;;                             `,(when lsp-metamath-zero-warn-unnecessary-parens-enable
    ;;                                 "--warn-unnecessary-parens"))))
    :activation-fn (lsp-activate-on "metamath-zero")
    :server-id 'metamath-zero))

  ;; Enable semantic tokens on mode hook and disable on major mode change.
  (defvar metamath-zero-previous-semantic-tokens-value nil)
  (setq metamath-zero-previous-semantic-tokens-value lsp-semantic-tokens-enable)
  (add-hook 'mm0-mode-hook
    #'(lambda ()
        (unless lsp-semantic-tokens-enable
          (lsp-semantic-tokens-mode))))
  (add-hook 'change-major-mode-hook
    #'(lambda ()
        (unless metamath-zero-previous-semantic-tokens-value
          (lsp-semantic-tokens-mode))))

  )

(with-eval-after-load 'eglot
  (defcustom lsp-metamath-zero-command "mm0-rs server"
    "Command to run metamath zero lsp server."
    :type 'string
    :group 'lsp-metamath-zero)
  (add-to-list 'eglot-server-programs
               `(metamath-zero-mode . ,lsp-metamath-zero-command)))

(define-key)
(provide 'metamath-zero-mode)
;;; metamath-zero-mode.el ends here
