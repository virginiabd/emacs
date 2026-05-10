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

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

(elpaca compat)
(elpaca-wait)

;; ======================================== 
;;; CORE SETTINGS (CONFIGURAÇÕES NATIVAS DO EMACS)

;; FONTE
(defvar my/font "Berkeley Mono ExtraCondensed Retina")
(defvar my/line-spacing 1)
(defvar my/size 140)

(set-face-attribute 'default nil :font my/font :height my/size)
(setq-default line-spacing my/line-spacing)

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
  (redisplay-skip-fontification-on-input t)
  (uniquify-buffer-name-style 'forward)
  (display-line-numbers-type 'relative)
  ;; (display-line-numbers-width-start t)
  (warning-minimum-level :emergency)
  (display-line-numbers-width 4)
  (initial-major-mode 'org-mode)
  (initial-scratch-message "")
  (ring-bell-function 'ignore)
  (split-width-threshold 100)
  (inhibit-startup-message t)
  (treesit-font-lock-level 4)
  (message-truncate-lines t)
  (echo-keystrokes 0.1)
  (use-short-answers t)
  (use-dialog-box nil)
  (truncate-lines t)
  ;; minibuffer
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  (read-extended-command-predicate
   #'command-completion-default-include-p)
  (switch-to-buffer-obey-display-actions t)
  (enable-recursive-minibuffers t)
  (lazy-highlight-initial-delay 0)
  (resize-mini-windows 'grow-only)
  (history-length 25)
  ;; editing
  (kill-do-not-save-duplicates t)
  (sentence-end-double-space nil)
  (tab-always-indent 'complete)
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
  ;; buffers
  (defun skip-these-buffers (_window buffer _bury-or-kill)
    "Function for `switch-to-prev-buffer-skip'."
    (string-match "\\*[^*]+\\*" (buffer-name buffer)))
  (setq switch-to-prev-buffer-skip 'skip-these-buffers)
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
  (global-unset-key (kbd "C-<wheel-down>"))
  (global-unset-key (kbd "C-<wheel-up>"))
  (global-unset-key (kbd "C-x C-z"))
  (global-unset-key (kbd "C-z"))
  ;; ui
  (set-face-attribute 'tooltip nil :font my/font)

  :bind
  ("C-="     . text-scale-increase)
  ("C--"     . text-scale-decrease)
  ("C-<tab>" . other-window))

;; ======================================== 
;; CUSTOM FUNCTIONS
(defun my/jump-to-end-of-block ()
  "Jump to the end of the current block."
  (interactive)
  (beginning-of-defun)
  (forward-sexp))

;; ======================================== 
;; COMANDOS/ATALHOS
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

    ;; --- search
    "s"   '(:ignore t :wk "search")
    "s r" '(consult-recent-file :wk "recent files")
    "s l" '(consult-line-multi :wk "line in files")
    "s d" '(consult-dir :wk "recent directories")
    "s g" '(consult-ripgrep :wk "ripgrep")
    "s o" '(consult-outline :wk "outline")
    "s t" '(consult-theme :wk "themes")
    "s i" '(consult-imenu :wk "imenu")
    "s s" '(consult-line :wk "line")
    "s f" '(consult-fd :wk "file")

    ;; --- windows
    "w"         '(:ignore t :wk "windows")
    "w <up>"    '(buf-move-up :wk ("↑" . "move up"))
    "w <down>"  '(buf-move-down :wk ("↓" . "move down"))
    "w <left>"  '(buf-move-left :wk ("←" . "move left"))
    "w <right>" '(buf-move-right :wk ("→" . "move right"))
    "w w"       '(evil-window-split :wk "horizontal split")
    "w v"       '(evil-window-vsplit :wk "vertical split")
    "w c"       '(evil-window-delete :wk "close window")
    "w n"       '(evil-window-new :wk "new window"))
    )

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

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (setopt evil-collection-mode-list '(dashboard dired ibuffer magit))
  (evil-collection-init))

(use-package evil-commentary
  :ensure t
  :after evil
  :config
  (evil-commentary-mode))

(use-package evil-goggles
  :ensure t
  :custom
  (evil-goggles-duration 0.100)
  (evil-goggles-enable-paste nil)
  :config
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))

;; ======================================== 
;;; UI (INTERFACE DE USUÁRIO)

;; PACOTE DE ÍCONES
(use-package nerd-icons
  :ensure t)

;; DOOM MODELINE (BARRINHA - FRESCURAS DO LUCAS)
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
  (doom-modeline-modal t)
  (doom-modeline-icon t)
  :config
  (defun doom-modeline-check-icon (_icon _unicode _text &optional _face) "")
  (setopt doom-modeline-always-show-macro-register t)
  (setopt doom-modeline-buffer-modification-icon nil)
  (custom-set-faces
   '(mode-line ((t (:inherit default :height 120 :weight normal))))
   '(mode-line-inactive ((t (:inherit default :height 120 :weight normal)))))
  (add-hook 'doom-modeline-mode-hook
            (lambda ()
              (dolist (face (face-list))
                (when (string-prefix-p "doom-modeline" (symbol-name face))
                  (set-face-attribute face nil :weight 'normal :slant 'normal)))))
  (doom-modeline-mode 1))

(use-package pixel-themes
  :ensure nil
  :load-path "~/.config/emacs/themes"
  :config
  (add-to-list 'custom-theme-load-path "~/.config/emacs/themes")
  (pixel-themes-set 'pixel-themes-fallenleaves))

(use-package rainbow-delimiters
  :ensure t
  :hook
  (prog-mode . rainbow-delimiters-mode))

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

(use-package restart-emacs
  :ensure t
  :defer t)

;; d/y/v + gs
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

(use-package buffer-move
  :ensure t
  :defer t)

;; ======================================== 
;;; COMPLETION

(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :custom
  (vertico-cycle nil)
  (vertico-count 6))

(use-package marginalia
  :ensure t
  :defer t
  :after vertico
  :init
  (marginalia-mode))
  
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t))

(use-package consult
  :ensure t
  :after vertico
  :defer t)

(use-package consult-dir
  :ensure t
  :defer t)

;; ======================================== 
;;; EDITING

(use-package move-text
  :ensure t
  :bind
  (("M-<up>"   . move-text-up)
   ("M-<down>" . move-text-down)))

;;; init.el ends here
