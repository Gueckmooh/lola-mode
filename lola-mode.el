;; Author Enzo Brignon
;; https://www.emacswiki.org/emacs/ModeTutorial

;;; Code:
(defvar lola-mode-hook nil)

(defvar lola-mode-map
  (let ((lola-mode-map (make-keymap)))
    (define-key lola-mode-map "\C-j" 'newline-and-indent)
    lola-mode-map)
  "Keymap for LoLA major mode")

(add-to-list 'auto-mode-alist '("\\.lola\\'" . lola-mode))

(defconst lola-font-lock-keywords-1
  (list
   ;; PLACE, TRANSITION, MARKING
   '("\\<\\(MARKING\\|PLACE\\|TRANSITION\\)\\>" . font-lock-builtin-face)
   '("\\('\\w*'\\)" . font-lock-variable-name-face))
  "Minimal highlighting expressions for LoLA mode.")

(defconst lola-font-lock-keywords-2
  (append lola-font-lock-keywords-1
		  (list
       ;; SAFE, CONSUME, PRODUCE
		   '("\\<\\(\\(?:CONSUM\\|PRODUC\\|SAF\\)E\\)\\>" . font-lock-keyword-face)))
		   ;; '("\\<\\(TRUE\\|FALSE\\)\\>" . font-lock-constant-face)))
  "Additional Keywords to highlight in LoLA mode.")


(defvar lola-font-lock-keywords lola-font-lock-keywords-2
  "Default highlighting expressions for LoLA mode.")

(defun lua-indent-line ()
  "Indent current line for Lua mode.
Return the amount the indentation changed by."
  (let (indent
        (case-fold-search nil)
        ;; save point as a distance to eob - it's invariant w.r.t indentation
        (pos (- (point-max) (point))))
    (back-to-indentation)
    (if (lua-comment-or-string-p)
        (setq indent (lua-calculate-string-or-comment-indentation)) ;; just restore point position
      (setq indent (max 0 (lua-calculate-indentation nil))))

    (when (not (equal indent (current-column)))
      (delete-region (line-beginning-position) (point))
      (indent-to indent))

    ;; If initial point was within line's indentation,
    ;; position after the indentation.  Else stay at same point in text.
    (if (> (- (point-max) pos) (point))
        (goto-char (- (point-max) pos)))

    indent))

(defun lola-indent-line ()
  "Indent current line as LoLA code."
  (interactive)
  (let
      ((pos (- (point-max) (point))))
    (progn
      (beginning-of-line)
      (if (bobp)
          (indent-line-to 0)		   ; First line is always non-indented
        (let ((not-indented t) cur-indent)
          (if (looking-at "^[ \t]*$") ; If the line we are looking at is the end of a block, then decrease the indentation

              (progn
                (save-excursion
                  (forward-line -1)
                  (setq cur-indent (- (current-indentation) default-tab-width)))
                (if (< cur-indent 0) ; We can't indent past the left margin
                    (setq cur-indent 0)))
            (save-excursion
              (while not-indented ; Iterate backwards until we find an indentation hint
                (forward-line -1)
                (if (looking-at "^[ \t]*$") ; This hint indicates that we need to indent at the level of the empty line
                    (progn
                      (setq cur-indent (current-indentation))
                      (setq not-indented nil))
                  (if (looking-at "^[ \t]*\\(PLACE\\|TRANSITION\\|MARKING\\|CONSUME[ \t]*$\\|PRODUCE[ \t]*$\\).*") ; This hint indicates that we need to indent an extra level
                      (progn
                        (setq cur-indent (+ (current-indentation) default-tab-width)) ; Do the actual indenting
                        (setq not-indented nil))
                    (if (bobp)
                        (setq not-indented nil)))))))
          (if cur-indent
              (indent-line-to cur-indent)
            (indent-line-to 0))))
      (if (> (- (point-max) pos) (point))
          (goto-char (- (point-max) pos)))
      )))

(defvar lola-mode-syntax-table
  (with-syntax-table (copy-syntax-table)
    ;; main comment syntax: begins with "--", ends with "\n"
    (modify-syntax-entry ?. "w")
    (modify-syntax-entry ?{ "<")
    (modify-syntax-entry ?} ">")

    ;; main string syntax: bounded by ' or "
    (modify-syntax-entry ?\' "\"")
    (modify-syntax-entry ?\" "\"")

    ;; single-character binary operators: punctuation
    (modify-syntax-entry ?: ".")
    ;; (modify-syntax-entry ?* ".")
    ;; (modify-syntax-entry ?/ ".")
    ;; (modify-syntax-entry ?^ ".")
    ;; (modify-syntax-entry ?% ".")
    ;; (modify-syntax-entry ?> ".")
    ;; (modify-syntax-entry ?< ".")
    ;; (modify-syntax-entry ?= ".")
    ;; (modify-syntax-entry ?~ ".")

    (syntax-table))
  "`lua-mode' syntax table.")

(defvar lola-mode-abbrev-table nil
  "Abbreviation table used in lua-mode buffers.")

(define-derived-mode lola-mode prog-mode "LoLA"
  "Major mode for editing LoLA code."
  :abbrev-table lola-mode-abbrev-table
  :syntax-table lola-mode-syntax-table
  :group 'lola
  (setq-local font-lock-defaults '(lola-font-lock-keywords
                                   nil nil nil nil))

  (setq-local comment-start "{ ")
  (setq-local comment-start-skip "{{*[ \t]*")
  (setq-local comment-end " }")
  (setq-local comment-end-skip "[ \t]*}")

  (setq-local indent-line-function           'lola-indent-line)
  )

(provide 'lola-mode)
