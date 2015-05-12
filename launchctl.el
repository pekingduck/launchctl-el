;;; launchctl.el --- View and manage Launchctl jobs on Mac OS X.

;; Author: Peking Duck <github.com/pekingduck>
;; Version: 1.0
;; Package-Version: 20150512
;; Package-Requires: (emacs "24"))
;; Keywords: tools, convenience
;; URL: http://github.com/pekingduck/launchctl-el

;; This file is not part of GNU Emacs.

;; Copyright (c) 2015 Peking Duck

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; This package lets you load/unload/start/stop/view jobs managed by launchd on
;; Mac OS X.
;;
;; - Type M-x launchctl RET
;;
;;; Code:

(require 'tabulated-list)

(defgroup launchctl nil
  "View and manage launchctl jobs."
  :group 'tools
  :group 'convenience)

(defcustom launchctl-use-header-line t
  "If non-nil, use the header line to display launchctl column titles."
  :type 'boolean
  :group 'launchctl)

(defface launchctl-name
  '((t (:weight bold)))
  "Face for job names in the display buffer."
  :group 'launchctl)

(defcustom launchctl-agent-directory "~/Library/LaunchAgents/"
  "Width of status column in the display buffer."
  :type 'number
  :group 'launchctl)

(defcustom launchctl-control-template "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
  <dict>
    <key>Label</key>
    <string>{LABEL}</string>
    <key>ProgramArguments</key>
    <array>
      <string></string>
    </array>
    <key>StandardOutPath</key>
    <string></string>
    <key>StandardErrorPath</key>
    <string></string>
  </dict>
</plist>"
  "The plist template for new job control files."
  :type 'string
  :group 'launchctl)

(defcustom launchctl-name-width 50
  "Width of name column in the display buffer."
  :type 'number
  :group 'launchctl)

(defcustom launchctl-pid-width 7
  "Width of process id column in the display buffer."
  :type 'number
  :group 'launchctl)

(defcustom launchctl-status-width 5
  "Width of status column in the display buffer."
  :type 'number
  :group 'launchctl)

(defvar launchctl-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map "q" 'quit-window)
    (define-key map "g" 'launchctl-refresh)
    (define-key map "n" 'launchctl-new)
    (define-key map "l" 'launchctl-load)
    (define-key map "u" 'launchctl-unload)
    (define-key map "s" 'launchctl-start)
    (define-key map "o" 'launchctl-stop)
    (define-key map "i" 'launchctl-info)
    (define-key map "e" 'launchctl-edit)
    (define-key map "h" 'launchctl-help)
    (define-key map "*" 'launchctl-filter)
    (define-key map "r" 'launchctl-restart)
    (define-key map "t" 'tabulated-list-sort)
    map))

(setq launchctl-filter-regex "")

(define-derived-mode launchctl-mode tabulated-list-mode "Launch Control"
  "Major mode for managing Launchctl jobs on Mac OS X."
  (setq default-directory launchctl-agent-directory)
  (add-hook 'tabulated-list-revert-hook 'launchctl-refresh nil t))

;;;###autoload
(defun launchctl()
  "View and manage Launchctl jobs on Mac OS X."
  (interactive)
  (switch-to-buffer (launchctl--noselect)))

(defun launchctl--noselect ()
  (let ((buffer (get-buffer-create "*Launchctl*")))
    (with-current-buffer buffer
      (launchctl-mode)
      (launchctl-refresh))
    buffer))

(defun launchctl-refresh ()
  "Display/Refresh the job list."
  (interactive)
  (let ((name-width launchctl-name-width)
        (pid-width launchctl-pid-width)
        (status-width launchctl-status-width))
    (setq tabulated-list-format
          (vector `("Name" ,name-width t)
                  `("PID" ,pid-width t)
                  `("Status" ,status-width nil))))
  (setq tabulated-list-use-header-line launchctl-use-header-line)
  (let ((entries '()))
    (with-temp-buffer
      (shell-command "launchctl list" t)
      ;; kill the header line without saving it to the kill-ring
      (goto-char (point-min))
      (end-of-line)
      (set-mark (line-beginning-position))
      (delete-region (region-beginning) (region-end))
      (dolist (l (split-string (buffer-string) "\n" t))
	(let ((fields (split-string l "\t" t)))
	  (if (or (string= launchctl-filter-regex "")
		  (string-match launchctl-filter-regex (nth 2 fields)))
	      (push (list (nth 2 fields) (vector (launchctl--prettify
						  (nth 2 fields))
						 (nth 0 fields)
						 (nth 1 fields))) entries)))))
    (setq tabulated-list-entries entries))
  (tabulated-list-init-header)
  (tabulated-list-print t))

(defun launchctl-help ()
  "Display help message for Launchctl Mode."
  (interactive)
  (message "[g]refresh; [n]ew control file; [l]oad job; [u]nload job; relo[a]d job\n[s]tart job; st[o]p job; [r]estart job; [i]nfo about job; [e]dit control file; [*]regex filtering; sor[t] by name"))

(defun launchctl-filter ()
  "Filter job list by regular expressions."
  (interactive)
  (setq launchctl-filter-regex (read-string "Regex (<RET> to clear): "))
  (launchctl-refresh))

(defun launchctl--ask-file-name ()
  (read-file-name "Control file: " launchctl-agent-directory))

(defun launchctl--entry-file-name ()
  "Check if <launchctl-agent-directory>/<job>.plist exists. If not the
user will be prompted for the location"
  (let ((file-name (expand-file-name (concat (tabulated-list-get-id) ".plist"))))
    (if (not (file-readable-p file-name))
      (launchctl--ask-file-name)
      file-name)))

(defun launchctl--command (&rest e)
  (shell-command (concat "launchctl " (mapconcat 'identity e " "))))

(defun launchctl-unload ()
  "Unload the job."
  (interactive)
  (launchctl--command "unload" launchctl--entry-file-name)
  (launchctl-refresh))

(defun launchctl-load ()
  "Load the job."
  (interactive)
  (launchctl--command "load" (launchctl--entry-file-name))
  (launchctl-refresh))

(defun launchctl-edit ()
  "Edit the corresponding .plist for the job."
  (interactive)
  (find-file-other-window (launchctl--entry-file-name)))

(defun launchctl-new ()
  "Create a new job control file. The default directory is ~/Library/LaunchAgents."
  (interactive)
  (let ((file-name (launchctl--ask-file-name)))
    (let ((buf (get-file-buffer file-name))
	  (base-name (file-name-base file-name)))
      (if (eq buf nil)
	  (setq buf (get-buffer-create base-name)))
      (with-current-buffer buf
	(set-visited-file-name file-name)
	(if (equal (buffer-size) 0)
	    (progn
	      (insert launchctl-control-template) 
	      (while (search-forward "{LABEL}" nil t)
		(replace-match base-name nil t))
	      (set-auto-mode))))
      (switch-to-buffer-other-window buf))))

(defun launchctl-stop ()
  "Stop the job. Equivalent to \"launchctl stop <job>\""
  (interactive)
  (launchctl--command "stop" (tabulated-list-get-id))
  (launchctl-refresh))

(defun launchctl-start ()
  "Start the job. Equvalent to \"launchctl start <job>\""
  (interactive)
  (launchctl--command "start" (tabulated-list-get-id))
  (launchctl-refresh))

(defun launchctl-restart ()
  "Restart the job. The same as stop and then start." 
  (interactive)
  (let ((id (tabulated-list-get-id)))
    (launchctl--command "stop" id)
    (launchctl--command "start" id)
    (launchctl-refresh)))

(defun launchctl-info ()
  "Show detail info of the job. Equivalent to \"launchctl list <job>\""
  (interactive)
  (launchctl--command "list" (tabulated-list-get-id)))

(defun launchctl--prettify (name)
  (propertize name
              'font-lock-face 'launchctl-name
              'mouse-face 'highlight))

(provide 'launchctl)

;;; launchctl.el ends here
