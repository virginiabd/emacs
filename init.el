;;; init.el --- Emacs --- -*- lexical-binding: t; no-byte-compile: t; -*-
;; ===============================================================
;;; Commentary:
;; ===============================================================
;;; MAPA DE ATALHOS

;; Atalhos com a Tecla Líder `SPC' / `M-SPC':
;;   SPC ←       - Pular para o início da linha
;;   SPC →       - Pular para o final da linha
;;   SPC b       - Buscar e alternar entre buffers (via Consult)
;;   SPC c       - Abrir folha de cola do cheat-sh
;;   SPC d       - Abrir o gerenciador de arquivos (Dired)
;;   SPC f       - Buscar e abrir um arquivo
;;   SPC h       - Buscar documentação no DevDocs
;;   SPC k       - Fechar o buffer atual e sua janela
;;   SPC p       - Navegar e colar do histórico de cópia (Yank-pop)
;;   SPC t       - Abrir o terminal Ghostel
;;   SPC /       - Pular para qualquer local da tela (Flash)

;; `SPC-m' Marcação de Texto (Org-remark):
;;   SPC m m     - Marcar a região de texto selecionada
;;   SPC m l     - Marcar a linha atual
;;   SPC m d     - Deletar a marcação atual
;;   SPC m c     - Alterar o tipo da marcação atual
;;   SPC m o     - Abrir notas da marcação atual
;;   SPC m v     - Visualizar todas as notas
;;   SPC m r     - Destacar texto em vermelho
;;   SPC m b     - Destacar texto em blue

;; `SPC-s' Buscas (Consult):
;;   SPC s s     - Buscar linhas no buffer atual
;;   SPC s l     - Buscar linhas em múltiplos buffers aberto
;;   SPC s r     - Buscar arquivos recentes
;;   SPC s g     - Buscar texto usando Ripgrep
;;   SPC s f     - Buscar arquivos usando fd
;;   SPC s i     - Navegar pela estrutura do buffer via Imenu

;; `SPC-l' Ações do LSP (LSP-Bridge - apenas em Prog Mode):
;;   SPC l d     - Pular para a definição
;;   SPC l r     - Buscar referências
;;   SPC l c     - Chamar ações de código (Code Actions)
;;   SPC l n     - Renomear símbolo
;;   SPC l l     - Listar diagnósticos e erros do buffer

;; `SPC-r' Atalhos do Ruby (Apenas em Ruby Mode):
;;   SPC r i     - Abrir o REPL do Ruby (Inf-Ruby)
;;   SPC r r     - Enviar o buffer inteiro para o REPL
;;   SPC r s     - Enviar a região selecionada para o REPL
;;   SPC r l     - Enviar a linha atual para o REPL


;; Edição com múltiplos cursores:
;;   C-n           - select word at cursor
;;   n/q           - add next match/skip match
;;   Q             - remove current match
;;   TAB           - toggle cursor/extend mode
;;   c/d/i/a/r     - edit at all cursors
;;   S-<up>/<down> - adicionar cursor na linha acima/abaixo

;; Modificadores Globais e Teclas de Função:
;;   ESC         - Limpeza de contexto inteligente e cancelamento (DWIM)
;;   RET         - Inserir nova linha e indentar automaticamente
;;   C-=         - Aumentar o zoom do texto
;;   C--         - Diminuir o zoom do texto
;;   C-,         - Alternar exibição do popup Popper
;;   C-.         - Alternar entre os popups do Popper
;;   C-o         - Alternar o foco para a outra janela
;;   C-backspace - Deletar palavra para trás sem salvar no kill ring
;;   F2          - Alternar Dired para modo editável (WDired)

;; Atalhos com o Prefixo `C-c':
;;   C-c C-i       - Abrir o arquivo de configuração init.el
;;   C-c C-m       - Abrir o menu do Magit para o arquivo
;;   C-c C-r       - Reiniciar o Emacs
;;   C-c C-s       - Editar o arquivo atual com privilégios de Sudo
;;   C-c C-t       - Mudar o tema do Emacs (Consult-theme)
;;   C-c C-v       - Alternar o modo de linhas truncadas (Quebra de linha)
;;   C-c C-h       - Abrir documentação do Helpful para o símbolo sob o cursor
;;   C-c C-c       - Inserir caminho de diretório no minibuffer (Consult-dir)

;; Edição de Texto (Global / Escrita):
;;   M-up        - Mover a linha atual ou o bloco selecionado para cima
;;   M-down      - Mover a linha atual ou o bloco selecionado para baixo
;; ===============================================================
;;; Code:

;; elpaca: gerenciador de pacotes
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

;; ===============================================================
;;; CORE

;; configurações de fonte
(defvar my/font "Berkeley Mono ExtraCondensed Regular")
(defvar my/font-size 148)

;; configurações nativas do emacs
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
  (initial-major-mode 'text-mode)
  (display-line-numbers-width 4)
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
  (set-face-attribute 'default nil :family my/font :height my/font-size)
  (set-face-attribute 'minibuffer-nonselected nil :background)
  (set-face-attribute 'tooltip nil :family my/font)
  (setq-default line-spacing 0)
  
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

  ;; system
  (setq custom-file (locate-user-emacs-file "custom-vars.el"))
  (add-hook 'prog-mode-hook 'display-line-numbers-mode)
  (setopt native-comp-async-query-on-exit t)
  (load custom-file 'noerror 'nomessage)
  (put 'narrow-to-region 'disabled nil)

  ;; smart context clearing and quit handler
  (define-key key-translation-map (kbd "ESC") (kbd "C-g"))
  (define-advice keyboard-quit (:around (quit) quit-context-dwim)
    (cond
    ((and (region-active-p)
          (not (active-minibuffer-window)))
      (keyboard-quit))
    ((derived-mode-p 'completion-list-mode)
      (delete-completion-window))
    ((active-minibuffer-window)
      (if (minibufferp)
          (minibuffer-keyboard-quit)
        (abort-recursive-edit)))
    (t
     (unless (or defining-kbd-macro executing-kbd-macro)
       (apply orig-fun args)))))

  ;; add option `d', allowing a quick preview of the diff of what you're asked to save.
  (add-to-list 'save-some-buffers-action-alist
               (list "d"
                     (lambda (buffer) (diff-buffer-with-file (buffer-file-name buffer)))
                     "show diff between the buffer and its file"))
  :bind
  ("C-=" . text-scale-increase)
  ("C--" . text-scale-decrease)
  ("RET" . newline-and-indent))

;; ===============================================================
;;; CUSTOM FUNCTIONS

;; fechar buffer e janela
(defun my/kill-buffer-window ()
  "Kill the current buffer and close its window."
  (interactive)
  (let ((buffer (current-buffer)))
    (when (and (> (count-windows) 1)
               (not (one-window-p)))
      (delete-window))
    (kill-buffer buffer)))

;; melhor `C-<backspace>'
(defun my/delete-dont-kill (arg)
  "Delete characters backward until encountering the beginning of a word.
   With argument ARG, do this that many times. Don't add to kill ring."
  (interactive "p")
  (delete-region (point) (progn (backward-word arg) (point))))
(defun my/backward-delete ()
  "Delete a word, a character, or whitespace."
  (interactive)
  (cond
   ((looking-back (rx (char word)) 1)
    (my/delete-dont-kill 1))
   ((looking-back (rx (seq (char word) (= 1 blank))) 1)
	(my/delete-dont-kill 1))
   ((looking-back (rx (char blank)) 1)
    (delete-horizontal-space t))
   (t
    (backward-delete-char-untabify 1))))

;; acesso rápido a folhas de comandos gerais (linux, git, linguagens, etc)
(defun cheat-sh ()
  "Query cheat.sh and display the result in a dedicated buffer."
  (interactive)
  (let* ((input (read-string "cheat.sh: "))
         (parts (split-string input " " t))
         (path  (if (cdr parts)
                    (format "%s/%s"
                            (car parts)
                            (url-hexify-string (string-join (cdr parts) " ")))
                  (url-hexify-string (car parts))))
         (buffer (get-buffer-create "*cheat.sh*"))
         (cmd    (format "curl -s 'cheat.sh/%s'" path)))
    (with-current-buffer buffer
      (read-only-mode -1)
      (erase-buffer)
      (insert (concat "cheat.sh: " input "\n"))
      (read-only-mode 1))
    (switch-to-buffer buffer)
    (cheat-sh--fetch cmd buffer)))

(defun cheat-sh--fetch (cmd buffer &optional)
  "Execute CMD as a shell command and stream output into buffer."
  (make-process
   :name "cheat-sh-fetch"
   :buffer (generate-new-buffer "*cheat-sh-temp*")
   :command (list "sh" "-c" cmd)
   :sentinel
   (lambda (proc _event)
     (when (eq (process-status proc) 'exit)
       (let ((output (with-current-buffer (process-buffer proc)
                       (buffer-string))))
         (kill-buffer (process-buffer proc))
         (with-current-buffer buffer
           (read-only-mode -1)
           (insert output)
           (ansi-color-apply-on-region (point-min) (point-max))
           (goto-char (point-min))
           (read-only-mode 1)))))))

;; ===============================================================
;;; KEYBINDINGS

;; painel vertical de atalhos
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

  (my/keys ;; diversos
    "<left>"  '(evil-beginning-of-line :wk ("←" . "beg of line"))
    "<right>" '(evil-end-of-line :wk ("→" . "end of line"))
    "k" '(my/kill-buffer-window :wk "kill buffer")
    "b" '(consult-buffer :wk "search buffer")
    "p" '(consult-yank-pop :wk "copy hist")
    "/" '(flash-jump :wk "jump anywhere")
    "d" '(dired-jump :wk "file manager")
    "h" '(devdocs-lookup :wk "devdocs")
    "c" '(cheat-sh :wk "cheat sheet")
    "f" '(find-file :wk "find file")
    "t" '(ghostel :wk "terminal"))

  (my/keys ;; marcação de texto
    "m"  '(:ignore t :wk "mark text")
    "ml" '(org-remark-mark-line :wk "mark line")
    "md" '(org-remark-delete :wk "mark delete")
    "mc" '(org-remark-change :wk "mark change")
    "mm" '(org-remark-mark :wk "mark region")
    "mo" '(org-remark-open :wk "open note")
    "mv" '(org-remark-view :wk "view note")
    ;; custom
    "mr" '(org-remark-mark-red :wk "text red")
    "mb" '(org-remark-mark-blue :wk "mark blue"))

  (my/keys ;; buscas
    "s"   '(:ignore t :wk "search")
    "s r" '(consult-recent-file :wk "recent files")
    "s l" '(consult-line-multi :wk "search line in files")
    "s b" '(consult-bookmark :wk "search bookmarks")
    "s g" '(consult-ripgrep :wk "ripgrep")
    "s i" '(consult-imenu :wk "imenu")
    "s s" '(consult-line :wk "search line")
    "s f" '(consult-fd :wk "search file"))

  (my/keys ;; lsp (pular para definição, code actions, etc)
    :keymaps '(prog-mode-map)
    "l"   '(:ignore t :wk "lsp actions")
    "l l" '(lsp-bridge-diagnostic-list :wk "list errors")
    "l r" '(lsp-bridge-find-references :wk "references")
    "l c" '(lsp-bridge-code-action :wk "code actions")
    "l d" '(lsp-bridge-find-def :wk "definition")
    "l n" '(lsp-bridge-rename :wk "rename"))

  (my/keys ;; atalhos em arquivos ruby
    :keymaps '(ruby-mode-map ruby-ts-mode-map)
    "r"   '(:ignore t :wk "ruby")
    "r r" '(ruby-send-buffer :wk "send buffer")
    "r s" '(ruby-send-region :wk "send region")
    "r l" '(ruby-send-line :wk "send line")
    "r i" '(inf-ruby :wk "open repl"))
  
  (general-def ;; atalhos sem which-key 
    :keymaps 'global
    :states  '(normal insert visual emacs)
    "C-<backspace>" 'my/backward-delete
    "<f2>" 'wdired-change-to-wdired-mode   
    "C-,"  'popper-toggle
    "C-."  'popper-cycle
    "C-o"  'other-window)
  
  (general-def ;; atalhos em `C-c'
    :keymaps 'global
    "C-c C-m" '(magit-file-dispatch :wk ("C-m" . "magit file"))
    "C-c C-v" '(visual-line-mode :wk "truncated lines")
    "C-c C-r" '(restart-emacs :wk "restart emacs")
    "C-c C-b" '(bookmark-set :wk "set a bookmark")
    "C-c C-t" '(consult-theme :wk "change theme")
    "C-c C-h" '(helpful-at-point :wk "helpful")
    "C-c C-s" '(sudo-edit :wk "edit with sudo")
    "C-c C-d" '(consult-dir :wk "insert path")
    "C-c C-i"   '((lambda () (interactive)
                (find-file (locate-user-emacs-file "init.el")))
              :wk ("C-i" . "init.el")))
    
  (general-unbind ;; remoção de atalhos não usados
    :keymaps 'global
    "C-<wheel-down>" "C-<wheel-up>" "C-x C-z" "C-c ^" "C-z")
  (general-unbind
    :keymaps 'emacs-lisp-mode-map
    "C-c C-b" "C-c C-e" "C-c C-f")
  (general-unbind
    :keymaps 'winner-mode-map
    "C-c <left>" "C-c <right>"))

;; comandos do vim
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
  (evil-mode 1))

;; extensão de comandos do vim
(use-package evil-collection
  :ensure t
  :after evil
  :config
  (setopt evil-collection-mode-list '(dired ibuffer magit))
  (evil-collection-init))

;; comentar linhas e blocos com `gcc' `gcap', etc
(use-package evil-commentary
  :ensure t
  :after evil
  :config
  (evil-commentary-mode))

;; destaca com cor região de ações do vim (copiar, recortar, etc)
(use-package evil-goggles
  :ensure t
  :custom
  (evil-goggles-duration 0.100)
  (evil-goggles-enable-paste nil)
  :config
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))

(use-package evim
  :ensure t
  :after evil
  :config
  (evim-setup-global-keys)
  (define-key evil-normal-state-map (kbd "C-<up>") nil)
  (define-key evil-normal-state-map (kbd "C-<down>") nil)
  (define-key evil-normal-state-map (kbd "S-<up>") #'evim-add-cursor-up)
  (define-key evil-normal-state-map (kbd "S-<down>") #'evim-add-cursor-down))

;; painel de comandos usado pelo magit
(use-package transient
  :ensure nil
  :defer t)

;; ===============================================================
;;; UI

;; define posição fixa para algumas janelas (magit, dired)
(use-package window
  :ensure nil
  :custom
  (display-buffer-alist
   '(("\\`magit:"
      (display-buffer-in-side-window)
      (window-height . 0.3)
      (side . bottom)
      (slot . 0))
     ((derived-mode . dired-mode)
      (display-buffer-in-side-window)
      (window-height . 0.3)
      (side . bottom)
      (slot . 0)))))

;; transforma janelas especificadas em popups
;; `C-,' para exibir/ocultar popup, `C-.' para percorrer popups abertos 
(use-package popper
  :ensure t
  :defer t
  :init
  (setopt popper-window-height 16)
  (setopt popper-reference-buffers
          '("^\\*ghostel.*\\*" "\\*eldoc\\*" "\\*cheat.sh*\\*$"
            compilation-mode
            inf-ruby-mode
            devdocs-mode
            helpful-mode
            ghostel-mode
            help-mode))
  (setopt popper-mode-line "")
  (popper-mode +1))

;; ícones usados na interface e odeline
(use-package nerd-icons
  :ensure t)

;; ícones usados no dired
(use-package nerd-icons-dired
  :ensure t
  :hook
  (dired-mode . nerd-icons-dired-mode))

;; ícones usados nas listas do vertico
(use-package nerd-icons-completion
  :ensure t
  :after(:all nerd-icons marginalia)
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; temas
(use-package pixel-themes
  :ensure (:host github :repo "lucasobx/pixel-themes")
  :config
  (pixel-themes-mode 1)
  (pixel-themes-load-theme 'pixel-themes-psygnosia))

;; temas
(use-package doric-themes
  :ensure t
  :defer t)

;; colore parênteses, chaves e colchetes
(use-package rainbow-delimiters
  :ensure t
  :hook
  (prog-mode . rainbow-delimiters-mode))

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
  (doom-modeline-height 25)
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

;; exibe quadrado colorido ao lado da definição de uma cor 
(use-package colorful-mode
  :ensure t
  :custom
  (colorful-use-prefix t)
  (colorful-prefix-string "■ ")
  (colorful-only-strings nil)
  (css-fontify-colors nil)
  :config
  (global-colorful-mode t)
  (add-to-list 'global-colorful-modes 'helpful-mode))

;; traduz códigos ANSI em cores e estilos
(use-package ansi-color
  :ensure nil
  :hook
  (compilation-filter . ansi-color-compilation-filter)
  :init
  (setenv "MANROFFOPT" "-P-c"))

;; marca linhas modificadas
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

;; ===============================================================
;;; NAVIGATION

;; bookmarks
(use-package bookmark
  :ensure nil
  :custom
  (bookmark-fringe-mark nil)
  (bookmark-save-flag 1))

;; navega para qualquer ponto na tela visível, `SPC-/'
;; também pode ser usado com `gs' e combinado com ações `y/p/d/v'
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

;; file manager
(use-package dired
  :ensure nil
  :hook
  (dired-mode . dired-hide-details-mode)
  (dired-mode . dired-omit-mode)
  (dired-mode . hl-line-mode)
  :custom
  (dired-listing-switches "-lah --almost-all --group-directories-first --sort=extension")
  (dired-hide-details-hide-absolute-location t)
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'top)
  (dired-omit-files "^\\.")
  (dired-free-space nil)
  (dired-dwim-target t))

;; permite renomear arquivos no dired como se fosse texto comum
;; `<f2>' para ativar, `C-c C-c' para aceitar modificação e `C-c ESC' para rejeitar
(use-package wdired
  :ensure nil
  :commands (wdired-change-to-wdired-mode))

;; ===============================================================
;;; TREESITTER

;; configura gramática para markdown
(use-package markdown-ts-mode
  :ensure nil)

;; configura gramática para ruby 
(use-package ruby-ts-mode
  :ensure nil
  :mode ("\\.rb\\'" "Rakefile\\'" "Gemfile\\'")
  :custom
  (ruby-indent-level 2)
  :config
  (add-to-list 'treesit-language-source-alist
               '(ruby "https://github.com/tree-sitter/tree-sitter-ruby" "master" "src")))

;; configura gramática para python
(use-package python-ts-mode
  :ensure nil
  :mode "\\.py\\'"
  :config
  (add-to-list 'treesit-language-source-alist
               '(ruby "https://github.com/tree-sitter/tree-sitter-python" "master" "src")))

;; ===============================================================
;;; LSP

;; instala gramáticas automaticamente, quando possível
;; caso não funcione, instalar manualmente com `M-x' `treesit-install-language-grammar'
(use-package treesit-auto
  :ensure t
  :after emacs
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode t))

;; abrir irb/pry em arquivos ruby
(use-package inf-ruby
  :ensure t
  :hook
  (ruby-ts-mode . inf-ruby-minor-mode)
  :config
  (when (executable-find "pry")
    (add-to-list 'inf-ruby-implementations '("pry" . "pry"))
    (setq inf-ruby-default-implementation "pry"))
  (add-hook 'inf-ruby-mode-hook
            (lambda ()
              (set-process-query-on-exit-flag
               (get-buffer-process (current-buffer)) nil))))

;; instala servidores para qualquer linguagem automaticamente
(use-package mason
  :ensure t
  :config
  (mason-setup))

;; cliente lsp: conecta código ao lsp server e fornece sugestões de código, ações, etc
(use-package lsp-bridge
  :ensure '(lsp-bridge :type git :host github :repo "manateelazycat/lsp-bridge"
            :files (:defaults "*.el" "*.py" "acm" "core" "langserver" "multiserver" "resources")
            :build (:not compile))
  :custom
  (lsp-bridge-ruby-lsp-server "ruby-lsp")
  (lsp-bridge-python-lsp-server "pyright")
  (lsp-bridge-enable-document-highlight t)
  (lsp-bridge-enable-auto-format-code t)
  (lsp-bridge-enable-hover-diagnostic t)
  (lsp-bridge-enable-diagnostics t)
  (lsp-bridge-enable-org-babel t)
  (acm-enable-doc nil)
  (acm-menu-length 5)
  :config
  (setopt lsp-bridge-default-mode-hooks
          '(emacs-lisp-mode-hook
            python-ts-mode-hook
            bash-ts-mode-hook
            ruby-ts-mode-hook
            ruby-mode-hook
            org-mode-hook))
  (global-lsp-bridge-mode))

;; documentação exibida na echo-area para comandos do emacs
(use-package eldoc
  :ensure nil
  :custom
  (eldoc-help-at-pt t)
  (eldoc-documentation-strategy 'eldoc-documentation-compose)
  (eldoc-echo-area-display-truncation-message nil)
  (eldoc-echo-area-prefer-doc-buffer t)
  (eldoc-echo-area-use-multiline-p nil)
  :init
  (global-eldoc-mode))

;; ===============================================================
;;; COMPLETION

;; abre o minibuffer em forma de lista/autocomplete
(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :custom
  (vertico-cycle nil)
  (vertico-count 6)
  :config
  ;; add a visual indicator to the currently selected candidate
  (advice-add #'vertico--format-candidate :around
              (lambda (orig cand prefix suffix index _start)
                (setq cand (funcall orig cand prefix suffix index _start))
                (concat
                 (if (= vertico--index index)
                     (propertize "» " 'face '(:foreground "#768c9c" :weight bold))
                   "  ")
                 cand))))

;; adiciona anotações nos itens das listagens do vertico
(use-package marginalia
  :ensure t
  :defer t
  :after vertico
  :init
  (marginalia-mode)
  :config
  ;; restrict annotations to 'face' and 'command' categories
  (setopt marginalia-annotators
          (mapcar (lambda (pair)
                    (if (memq (car pair) '(face command))
                        pair
                      (cons (car pair) '(none))))
                  marginalia-annotators)))

;; busca fuzzy e fora de ordem em listas do vertico
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t))

;; pré-visualização de arquivos, temas, etc, em consultas com o vertico
(use-package consult
  :ensure t
  :after vertico
  :defer t
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  (setopt xref-show-xrefs-function #'consult-xref
          xref-show-definitions-function #'consult-xref)
  (setopt completion-in-region-function #'consult-completion-in-region)
  :config
  (setopt consult-fd-args
          '("fd" "--color=auto" "--full-path" "--hidden"))
  (setopt consult-buffer-sources '(consult-source-buffer))
  (setopt consult-buffer-filter
          (append consult-buffer-filter
                  '("\\*Async Shell Command\\*" "\\*eldoc\\*" "Output\\*$"
                    "annotations.org" "\\*Messages\\*" "\\*lsp-bridge.*\\*"
                    "\\*helpful.*\\*" "\\*ghostel.*\\*")))
  ;; prevent dired buffer from surfacing in consult-buffer when hidden by popper.
  (defun my/consult-buffer-filter-modes (buffers)
    (cl-remove-if
     (lambda (buf)
       (let ((buffer (if (stringp buf) (get-buffer buf) (cdr buf))))
         (when buffer
           (memq (buffer-local-value 'major-mode buffer) '(dired-mode)))))
     buffers))
  (advice-add #'consult--buffer-query :filter-return #'my/consult-buffer-filter-modes))

;; colar caminho de diretório/arquivo em consultas no vertico ou outros locais 
(use-package consult-dir
  :ensure t
  :defer t)

;; snippets/templates de código. dependência para o lsp-bridge
(use-package yasnippet
  :ensure t
  :defer t)

;; ==============================================================
;;; EDITING

;; movimentar linha ou bloco selecionado para cima/baixo com `M+up' e `M+down'
(use-package move-text
  :ensure t
  :bind
  (("M-<up>" . move-text-up)
   ("M-<down>" . move-text-down)))

;; editar arquivos como adm/sudo
(use-package sudo-edit
  :ensure t
  :defer t)

;; ===============================================================
;;; WRITING & READING

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
  (org-agenda-files '("~/Documents/org"))
  (org-hide-emphasis-markers t)
  (org-return-follows-link t)
  (org-hide-leading-stars t)
  (org-auto-align-tags nil)
  (org-special-ctrl-a/e t)
  (org-tags-column 0)
  (org-ellipsis " ∷")
  :config
  (setopt evil-auto-indent nil)
  (set-face-attribute 'org-ellipsis nil :underline nil))

;; integra evil ao org-mode
(use-package evil-org
  :ensure t
  :after org
  :hook
  (org-mode . evil-org-mode))

;; centraliza conteúdo na tela
(use-package olivetti
  :ensure t
  :hook
  (org-mode . olivetti-mode))

;; oculta símbolos de marcações no texto (negrito, itálico, links, etc)
(use-package org-appear
  :ensure (:host github :repo "awth13/org-appear")
  :hook
  (org-mode . org-appear-mode)
  :custom
  (org-appear-autoemphasis t))

;; estilo mais moderno no org-mode
(use-package org-modern
  :ensure t
  :hook
  (org-mode . org-modern-mode)
  :custom
  (org-modern-star 'replace)
  (org-modern-replace-stars '("◉" "○" "◈" "◇" "•"))
  (org-modern-checkbox nil)
  (org-modern-list '((?- . "›") (?+ . "»") (?* . "»»"))))

;; marcação de texto e criação de canetas customizadas
(use-package org-remark
  :ensure t
  :init
  (org-remark-global-tracking-mode +1)
  :custom
  (org-remark-notes-file-name "~/.config/emacs/org/annotations.org")
  :config
  (org-remark-create "custom1"
    'mode-line-active
    '(CATEGORY "custom")))

;; ===============================================================
;;; TERMINAL

(use-package ghostel
  :ensure t
  :defer t
  :hook
  (ghostel-mode . evil-emacs-state))

;; ===============================================================
;;; DOCS

;; melhora a documentação nativa do emacs
(use-package helpful
  :ensure t
  :defer t)

;; documentações para diversas linguagens e frameworks (ruby, python, pytorch, etc)
(use-package devdocs
  :ensure t
  :defer t
  :config
  (setopt devdocs-header-line nil))

;; força uso da fonte padrão no buffer do devdocs e helpful
(use-package shr
  :ensure nil
  :config
  (setq shr-use-fonts nil))

;; ===============================================================
;;; VERSION CONTROL

;; cliente git
(use-package magit
  :ensure t
  :defer t
  :config
  (keymap-set transient-map "<escape>" 'transient-quit-one))

;;; init.el ends here
