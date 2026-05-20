;;; init.el --- Emacs --- -*- lexical-binding: t; no-byte-compile: t; -*-
;; ===============================================================
;;; Commentary:
;;; Code:

(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  (elpaca-use-package-mode))

(use-package compat
  :ensure (:wait t))

;; ======================================== 
;;; CORE SETTINGS

;; fonte
(defvar my/font "Berkeley Mono ExtraCondensed Regular")
(defvar my/size 148)

(set-face-attribute 'default nil :font my/font :height my/size)
(setq-default line-spacing 0.1)

(use-package emacs
  :ensure nil
  :init
  (defun display-startup-echo-area-message () (message ""))
  (global-auto-revert-mode t)
  (file-name-shadow-mode 1)
  (delete-selection-mode 1)
  (global-hl-line-mode -1)
  (electric-indent-mode 1)
  (electric-pair-mode 1)
  (column-number-mode 1)
  (save-place-mode 1)
  (tooltip-mode -1)
  (savehist-mode 1)
  (recentf-mode 1)
  (winner-mode 1)

  :custom
  ;; ui
  (display-fill-column-indicator-warning nil)
  (redisplay-skip-fontification-on-input t)
  (uniquify-buffer-name-style 'forward)
  (display-line-numbers-type 'relative)
  (warning-minimum-level :emergency)
  (ibuffer-human-readable-size t)
  (display-line-numbers-width 4)
  (initial-major-mode 'org-mode)
  (zone-all-windows-in-frame t)
  (initial-scratch-message "")
  (ring-bell-function 'ignore)
  (split-width-threshold 100)
  (inhibit-startup-message t)
  (treesit-font-lock-level 4)
  (message-truncate-lines t)
  (echo-keystrokes 0.1)
  (use-short-answers t)
  (use-dialog-box nil)
  (zone-all-frames t)
  (truncate-lines t)
  (line-spacing 1)
  ;; minibuffer
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  (read-extended-command-predicate
   #'command-completion-default-include-p)
  (switch-to-buffer-obey-display-actions t)
  (enable-recursive-minibuffers t)
  (lazy-highlight-initial-delay 0)
  (resize-mini-windows 'grow-only)
  (completion-eager-display 'auto)
  (completion-eager-update t)
  (history-length 25)
  ;; editing
  (treesit-auto-install-grammar t)
  (kill-do-not-save-duplicates t)
  (sentence-end-double-space nil)
  (tab-always-indent 'complete)
  (delete-pair-push-mark t)
  (treesit-enabled-modes t)
  (indent-tabs-mode nil)
  (tab-width 2)
  ;; files
  (auto-save-file-name-transforms
   '((".*" "~/.config/emacs/auto-saves/" t)))
  (find-file-suppress-same-file-warnings t)
  (global-auto-revert-non-file-buffers t)
  (kill-buffer-delete-auto-save-files t)
  (auto-save-no-message t)
  (make-backup-files nil)
  (create-lockfiles nil)
  ;; scroll
  (pixel-scroll-precision-use-momentum nil)
  (scroll-preserve-screen-position t)
  (mouse-wheel-progressive-speed nil)
  (delete-by-moving-to-trash t)
  (scroll-conservatively 101)
  (scroll-margin 10)
  (scroll-step 1)
  
  :config
  ;; ui
  (set-face-attribute 'default nil :family my/font :height my/size)
  (set-face-attribute 'minibuffer-nonselected nil :background)
  (set-face-attribute 'tooltip nil :family my/font)
  ;; minibuffer
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
  (add-hook 'minibuffer-setup-hook (lambda () (setq truncate-lines t)))
  (minibuffer-depth-indicate-mode 1)
  (minibuffer-electric-default-mode 1)
  ;; buffers
  (defun skip-these-buffers (_window buffer _bury-or-kill)
    "Function for `switch-to-prev-buffer-skip'."
    (string-match "\\*[^*]+\\*" (buffer-name buffer)))
  (setq switch-to-prev-buffer-skip 'skip-these-buffers)
  ;; benchmark
  (add-hook 'emacs-startup-hook
            (lambda () (message "Booted in %s." (emacs-init-time))))
  ;; system
  (setq custom-file (locate-user-emacs-file "custom-vars.el"))
  (add-hook 'prog-mode-hook 'display-line-numbers-mode)
  (setopt native-comp-async-query-on-exit t)
  (load custom-file 'noerror 'nomessage)
  (put 'narrow-to-region 'disabled nil)
  ;; bindings
  (define-advice keyboard-quit
      (:around (quit) quit-current-context)
    (if (active-minibuffer-window)
        (if (minibufferp)
            (minibuffer-keyboard-quit) (abort-recursive-edit))
      (unless (or defining-kbd-macro executing-kbd-macro)
        (funcall-interactively quit))))
  (define-key key-translation-map (kbd "ESC") (kbd "C-g"))
  ;; ui
  (set-face-attribute 'tooltip nil :font my/font)

  :bind
  ("C-=" . text-scale-increase)
  ("C--" . text-scale-decrease)
  ("C-;" . other-window)
  ("C-<wheel-down>" . nil)
  ("C-<wheel-up>" . nil)
  ("C-x C-z" . nil)
  ("C-z" . nil))

;; ======================================== 
;;; CUSTOM FUNCTIONS

(defun my/jump-to-end-of-block ()
  "Jump to the end of the current block."
  (interactive)
  (beginning-of-defun)
  (forward-sexp))

(defun my/kill-buffer-window ()
  "Kill the current buffer and close its window."
  (interactive)
  (let ((buffer (current-buffer)))
    (when (and (> (count-windows) 1)
               (not (one-window-p)))
      (delete-window))
    (kill-buffer buffer)))

;; ======================================== 
;;; KEYBINDINGS

;; painel de atalhos 
(use-package which-key
  :ensure nil
  :hook
  (after-init . which-key-mode)
  :config
  (setopt which-key-max-description-length 28
          which-key-add-column-padding 1
          which-key-min-display-lines 6
          which-key-prefix-prefix ""
          which-key-separator " → "
          which-key-idle-delay 0.3)
  (set-face-attribute 'which-key-note-face nil :height 1.0)
  (setopt which-key-sort-order 'which-key-local-then-key-order))

;; atalhos customizados
(use-package general
  :ensure (:wait t)
  :demand t
  :config
  (general-evil-setup)
  (general-create-definer my/keys
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "M-SPC")
  (my/keys
    ;; --- navigation
    "<right>" '(evil-end-of-line :wk ("→" . "end of line"))
    "<left>"  '(evil-beginning-of-line :wk ("←" . "beg of line"))
    "k"       '(my/kill-buffer-window :wk "kill buffer")
    "b"       '(consult-buffer :wk "search buffer")
    "y"       '(consult-yank-pop :wk "yank-pop")
    "d"       '(dired-jump :wk "file manager")
    "/"       '(flash-jump :wk "search jump")
    "f"       '(find-file :wk "find file")

   ;; --- config
    "e"   '(:ignore t :wk "emacs config")
    "e c" '((lambda () (interactive)
              (find-file (locate-user-emacs-file "init.el")))
            :wk "edit config")
    "e e" '(my/jump-to-end-of-block :wk "end of block")
    "e t" '(visual-line-mode :wk "truncated lines")
    "e f" '(eval-last-sexp :wk "eval expression")
    "e r" '(restart-emacs :wk "restart emacs")
    "e s" '(sudo-edit :wk "sudo edit file")

    ;; --- help
    "h"   '(:ignore t :wk "help")
    "h h" '(helpful-at-point :wk "at point")
    "h d" '(devdocs-lookup :wk "devdocs")

    ;; --- search
    "s"   '(:ignore t :wk "search")
    "s r" '(consult-recent-file :wk "recent files")
    "s l" '(consult-line-multi :wk "line in files")
    "s g" '(consult-ripgrep :wk "ripgrep")
    "s o" '(consult-outline :wk "outline")
    "s t" '(consult-theme :wk "themes")
    "s i" '(consult-imenu :wk "imenu")
    "s s" '(consult-line :wk "line")
    "s f" '(consult-fd :wk "file")

    ;; --- windows
    "w"         '(:ignore t :wk "windows")
    "w <right>" '(window-layout-rotate-clockwise :wk ("→" . "rotate clockwise"))
    "w <left>"  '(window-layout-flip-leftright :wk ("←" . "flip left-right"))
    "w <up>"    '(window-layout-flip-topdown :wk ("↑" . "flip top-down"))
    "w v"       '(evil-window-vsplit :wk "vertical split")
    "w c"       '(evil-window-delete :wk "close window")
    "w w"       '(evil-window-new :wk "new window"))

  (my/keys
    :keymaps '(ruby-mode-map ruby-ts-mode-map)
    "r"   '(:ignore t :wk "ruby")
    "i"   '(inf-ruby :wk "open repl")
    "r r" '(ruby-send-buffer :wk "send buffer")
    "r g" '(ruby-send-buffer-and-go :wk "send buffer and go")
    "r s" '(ruby-send-region :wk "send region")
    "r l" '(ruby-send-line :wk "send line"))
  
  (general-def
    :states '(normal insert visual)
    "M-y"   'consult-yank-pop
    "C-,"   'popper-toggle
    "C-."   'popper-cycle
    "<f12>" 'ghostel))

;; emulação de comandos do vim
(use-package evil
  :ensure (:wait t)
  :demand t
  :init
  (setopt evil-undo-system 'undo-redo
          evil-want-fine-undo t
          evil-want-integration t
          evil-want-keybinding nil
          evil-vsplit-window-right t
          evil-split-window-below t
          evil-shift-width 2)
  :config
  (define-key evil-normal-state-map (kbd "<escape>") #'keyboard-quit)
  (define-key evil-insert-state-map (kbd "C-y") 'yank)
  (define-key evil-normal-state-map (kbd "C-y") 'yank)
  (evil-set-initial-state 'vterm-mode 'emacs)
  (evil-mode 1))

;; coleção estendida de comandos do vim
(use-package evil-collection
  :ensure t
  :after evil
  :config
  (setopt evil-collection-mode-list '(dashboard dired ibuffer magit))
  (evil-collection-init))

;; comenter linhas ou blocos com `gcc'/`gc'/`gcap', etc
(use-package evil-commentary
  :ensure t
  :after evil
  :config
  (evil-commentary-mode))

;; realça ações do vim (seleção, etc)
(use-package evil-goggles
  :ensure t
  :custom
  (evil-goggles-duration 0.100)
  (evil-goggles-enable-paste nil)
  :config
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))

;; transient (magit)
;; speedbar ou alguma outra

;; ======================================== 
;;; UI

;; pacote de ícones
(use-package nerd-icons
  :ensure t)

;; ícones no file manager
(use-package nerd-icons-dired
  :ensure t
  :hook
  (dired-mode . nerd-icons-dired-mode))

;; ícones nos candidatos do minibuffer
(use-package nerd-icons-completion
  :ensure t
  :after(:all nerd-icons marginalia)
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; temas
(use-package doric-themes
  :ensure t
  :demand t
  :config
  (setq doric-themes-to-toggle '(doric-light doric-dark))
  (setq doric-themes-to-rotate doric-themes-collection)
  (doric-themes-select 'doric-mermaid)
  :bind
  (("<f5>" . doric-themes-toggle)
   ("C-<f5>" . doric-themes-select)
   ("M-<f5>" . doric-themes-rotate)))

;; barra de informações inferior
(use-package doom-modeline
  :ensure t
  :custom
  (doom-modeline-window-width-limit 0)
  (doom-modeline-total-line-number t)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-major-mode-icon t)
  (doom-modeline-check-icon nil)
  (nerd-icons-scale-factor 1.0)
  (doom-modeline-modal-icon t)
  (doom-modeline-height 34)
  (doom-modeline-modal t)
  (doom-modeline-icon t)
  :config
  (defun doom-modeline-check-icon (_icon _unicode _text &optional _face) "")
  (setopt doom-modeline-always-show-macro-register t)
  (setopt doom-modeline-buffer-modification-icon nil)
  (custom-set-faces
   '(mode-line ((t (:inherit default :height 135 :weight normal))))
   '(mode-line-inactive ((t (:inherit default :height 135 :weight normal)))))
  (add-hook 'doom-modeline-mode-hook
            (lambda ()
              (dolist (face (face-list))
                (when (string-prefix-p "doom-modeline" (symbol-name face))
                  (set-face-attribute face nil :weight 'normal :slant 'normal)))))
  (doom-modeline-mode 1))

;; colore parênteses, colchetes e chaves
(use-package rainbow-delimiters
  :ensure t
  :hook
  (prog-mode . rainbow-delimiters-mode))

;; colorful-mode
;; ansi-color

;; indicação de linhas modificadas
(use-package line-reminder
  :ensure t
  :hook
  (prog-mode . line-reminder-mode)
  :config
  (add-hook 'minibuffer-setup-hook (lambda () (line-reminder-mode -1)))
  (setopt line-reminder-show-option 'indicators)
  (setopt line-reminder-bitmap 'vertical-bar)
  (set-face-attribute 'line-reminder-modified-sign-face nil
                      :foreground (face-attribute 'line-number-current-line :foreground))
  (set-face-attribute 'line-reminder-saved-sign-face nil
                      :foreground (face-attribute 'default :background)))

;; ======================================== 
;;; NAVIGATION

;; gerenciador de arquivos
(use-package dired
  :ensure nil
  :hook
  (dired-mode . dired-hide-details-mode)
  (dired-mode . dired-omit-mode)
  (dired-mode . hl-line-mode)
  :custom
  (dired-listing-switches "-lah --almost-all --group-directories-first --sort=extension")
  (dired-hide-details-hide-absolute-location t) ; EMACS-31
  (dired-dwim-target t)
  (dired-omit-files "^\\.")
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-recursive-deletes 'top)
  (dired-recursive-copies 'always)
  (dired-free-space nil)
  :bind
  (:map dired-mode-map ("C-," . dired-omit-mode)))

(use-package popper
  :ensure t
  :defer t
  :init
  (setopt popper-window-height 15)
  (setopt popper-reference-buffers
          '("\\*Async Shell Command\\*"
            "^\\*ghostel.*\\*$"
            "\\*eldoc\\*"
            "Output\\*$"
            compilation-mode
            inf-ruby-mode
            devdocs-mode
            helpful-mode
            ghostel-mode
            dired-mode
            help-mode))
  (setopt popper-mode-line "")
  (popper-mode +1))

;; navegar para ponto específico da tela - `gs'/`SPC+/' - funciona com d/y/v 
(use-package flash
  :ensure (:host github :repo "Prgebish/flash")
  :commands (flash-jump flash-jump-continue flash-treesitter)
  :custom
  (flash-multi-window t)
  (flash-autojump t)
  (flash-nohlsearch t)
  (flash-char-jump-labels t)
  :init
  (with-eval-after-load 'evil
    (require 'flash-evil)
    (flash-evil-setup t)))

;; reiniciar emacs
(use-package restart-emacs
  :ensure t
  :defer t)

;; ======================================== 
;;; LSP

;; garante que o Emacs enxergue o path do sistema
(use-package exec-path-from-shell
  :ensure t
  :demand t
  :config
  (exec-path-from-shell-initialize))

;; analisador sintático (instala a gramática das linguagens automaticamente)
(use-package treesit-auto
  :ensure t
  :after emacs
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode t))

(use-package markdown-ts-mode
  :ensure nil
  :defer t)

;; dependência do lsp-bridge
(use-package yasnippet
  :ensure t
  :defer t)

(use-package inf-ruby
  :ensure t
  :hook
  (ruby-ts-mode . inf-ruby-minor-mode)
  :config
  (when (executable-find "pry")
    (add-to-list 'inf-ruby-implementations '("pry" . "pry"))
    (setq inf-ruby-default-implementation "pry")))

;; instala servidores lsp para qualquer linguagem
(use-package mason
  :ensure t
  :config
  (mason-setup))

;; cliente lsp: conecta a linguagem com o servidor correto 
(use-package lsp-bridge
  :ensure '(lsp-bridge :type git :host github :repo "manateelazycat/lsp-bridge"
            :files (:defaults "*.el" "*.py" "acm" "core" "langserver" "multiserver" "resources")
            :build (:not compile))
  :custom
  (lsp-bridge-ruby-lsp-server "ruby-lsp")
  (lsp-bridge-enable-document-highlight t)
  (lsp-bridge-enable-auto-format-code t)
  (lsp-bridge-enable-hover-diagnostic t)
  (lsp-bridge-enable-diagnostics t)
  (lsp-bridge-enable-org-babel t)
  :config
  (setopt lsp-bridge-default-mode-hooks
          '(emacs-lisp-mode-hook
            ruby-ts-mode-hook
            bash-ts-mode-hook
            ruby-mode-hook
            org-mode-hook))
  (global-lsp-bridge-mode))

;; eldoc

;; ======================================== 
;;; COMPLETION

;; ajustar consult

;; minibuffer em forma de lista para buscas e autocomplete
(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :custom
  (vertico-cycle nil)
  (vertico-count 6)
  :config
  (advice-add #'vertico--format-candidate :around
              (lambda (orig cand prefix suffix index _start)
                (setq cand (funcall orig cand prefix suffix index _start))
                (concat
                 (if (= vertico--index index)
                     (propertize "» " 'face '(:foreground "#768c9c" :weight bold))
                   "  ")
                 cand))))

;; anotações nos itens do minibuffer
(use-package marginalia
  :ensure t
  :defer t
  :after vertico
  :init
  (marginalia-mode))

;; fuzzy search fora de ordem
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t))

;; comandos de busca, navegação e pré-visualização
(use-package consult
  :ensure t
  :after vertico
  :defer t)
 
;; inserir caminhos em prompts do minibuffer
(use-package consult-dir
  :ensure t
  :defer t
  :bind
  ("C-c c" . consult-dir))

;; ======================================== 
;;; EDITING

;; mover linha com `M-<up>' e `M-<down>'
(use-package move-text
  :ensure t
  :bind
  (("M-<up>"   . move-text-up)
   ("M-<down>" . move-text-down)))

;; editar arquivos com sudo
(use-package sudo-edit
  :ensure t
  :defer t)

;; ======================================== 
;;; WRITING & READING

;; org-mode
(use-package org
  :ensure nil
  :hook
  ((org-mode . visual-line-mode)
   (org-mode . org-indent-mode)
   (org-mode . (lambda () (auto-fill-mode 0))))
  :custom
  (org-catch-invisible-edits 'show-and-error)
  (org-insert-heading-respect-content t)
  (org-cycle-hide-drawer-startup t)
  (org-hide-emphasis-markers t)
  (org-return-follows-link nil)
  (org-hide-leading-stars t)
  (org-auto-align-tags nil)
  (org-special-ctrl-a/e t)
  (org-tags-column 0)
  (org-ellipsis " ∷")
  :config
  (setopt evil-auto-indent nil)
  (set-face-attribute 'org-ellipsis nil :underline nil))

;; centraliza o conteúdo no buffer
(use-package olivetti
  :ensure t
  :hook
  (org-mode . olivetti-mode)
  :config
  (olivetti-body-width 80))

;; deixa bonitinho
(use-package org-modern
  :ensure t
  :after org
  :hook
  (org-mode . org-modern-mode)
  :custom
  (org-modern-star 'replace)
  (org-modern-replace-stars '("◉" "○" "◈" "◇" "•"))
  (org-modern-checkbox '((?X . "☑") (?\s . "☐")))
  (org-modern-list '((?- . "›") (?+ . "»") (?* . "⋙"))))

;; oculta os marcadores de negrito/itálico etc
(use-package org-appear
  :ensure (:host github :repo "awth13/org-appear")
  :hook
  (org-mode . org-appear-mode)
  :custom
  (org-appear-autoemphasis t))

;; grifar e anotar
(use-package org-remark
  :ensure t
  :init
  (org-remark-global-tracking-mode +1)
  :custom
  (org-remark-notes-file-name "~/.config/emacs/org/annotations.org")
  :config
  (org-remark-create "blue"
    '(:background "#1f3a5f" :foreground "#a0b9ba")
    '(CATEGORY "important"))
  (org-remark-create "text-red"
    '(:foreground "#aa0033")
    '(CATEGORY "important")))

;; pdf-tools

;; ======================================== 
;;; TERMINAL

(use-package ghostel
  :ensure t)

(use-package evil-ghostel
  :ensure t
  :after ghostel)

;; ======================================== 
;;; DOCS

;; alternativa à ajuda/doc integrada do emacs
(use-package helpful
  :ensure t
  :defer t)

;; documentações para tecnologias diversas
(use-package devdocs
  :ensure t
  :defer t
  :config
  (setopt devdocs-header-line nil))

(with-eval-after-load 'shr
  (set-face-attribute 'shr-text nil
                      :family my/font :height my/size :weight 'normal)
  (set-face-attribute 'shr-code nil
                      :family my/font :height my/size :weight 'normal))

;; ======================================== 
;;; VERSION CONTROL

(use-package magit
  :ensure t
  :defer t)

;;; init.el ends here
