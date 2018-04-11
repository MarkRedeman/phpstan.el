;;; phpstan.el --- Interface to PHPStan.             -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 15 Mar 2018
;; Version: 0.0.1
;; Keywords: tools, php
;; Homepage: https://github.com/emacs-php/phpstan.el
;; Package-Requires: ((emacs "24"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Static analyze for PHP code using PHPStan.
;; https://github.com/phpstan/phpstan

;;; Code:
(require 'php-project)
(require 'flycheck nil)


;; Variables:

;;;###autoload
(progn
  (defvar phpstan-configure-file nil)
  (make-variable-buffer-local 'phpstan-configure-file)
  (put 'phpstan-configure-file 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (and (eq 'root (car v)) (stringp (cdr v)))
                       (null v) (stringp v)))))

;;;###autoload
(progn
  (defvar phpstan-level "0")
  (make-variable-buffer-local 'phpstan-level)
  (put 'phpstan-level 'safe-local-variable
       #'(lambda (v) (or (null v)
                         (integerp v)
                         (and (stringp v)
                              (string-match-p "\\`[1-9][0-9]*\\'" v))))))

;;;###autoload
(progn
  (defvar phpstan-executable nil)
  (make-variable-buffer-local 'phpstan-executable)
  (put 'phpstan-executable 'safe-local-variable
       #'(lambda (v) (if (consp v)
                         (and (eq 'root (car v)) (stringp (cdr v)))
                       (null v) (stringp v)))))

;; Functions:
(defun phpstan-get-configure-file ()
  "Return path to phpstan configure file or `NIL'."
  (if phpstan-configure-file
      (if (and (consp phpstan-configure-file)
               (eq 'root (car phpstan-configure-file)))
          (expand-file-name (cdr phpstan-configure-file) (php-project-get-root-dir))
        phpstan-configure-file)
    (let ((dir (or (locate-dominating-file "phpstan.neon" default-directory)
                   (locate-dominating-file "phpstan.neon.dist" default-directory)))
          file)
      (when dir
        (setq file (expand-file-name "phpstan.neon.dist" dir))
        (if (file-exists-p file)
            file
          (expand-file-name "phpstan.neon" dir))))))

(defun phpstan-get-level ()
  "Return path to phpstan configure file or `NIL'."
  (cond
   ((null phpstan-level) "0")
   ((integerp phpstan-level) (int-to-string phpstan-level))
   (t phpstan-level)))

(defun phpstan-get-executable ()
  "Return PHPStan excutable file."
  (let ((executable (or phpstan-executable '(root . "vendor/bin/phpstan"))))
    (when (and (consp executable)
               (eq 'root (car executable)))
      (setq executable
            (expand-file-name (cdr executable) (php-project-get-root-dir))))
    (if (file-exists-p executable)
        executable
      (if (executable-find "phpstan")
          "phpstan"
        (error "PHPStan executable not found")))))

;;;###autoload
(when (featurep 'flycheck)
  (flycheck-define-checker phpstan-checker
    "PHP static analyzer based on PHPStan."
    :command ("phpstan" 
              "analyze" 
              "--no-progress"
              "--errorFormat=raw" 
              source)
    :working-directory (lambda (_) (php-project-get-root-dir))
    :enabled (lambda () (locate-dominating-file "phpstan.neon" default-directory))
    :error-patterns
    ((error line-start (1+ (not (any ":"))) ":" line ":" (message) line-end))
    :modes (php-mode)
    :next-checkers (php)))

(provide 'phpstan)
;;; phpstan.el ends here
