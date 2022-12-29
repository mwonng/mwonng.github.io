;;; build-site.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Michael Wang
;;
;; Author: Michael Wang <michael@wonng.com>
;; Maintainer: Michael Wang <michael@wonng.com>
;; Created: December 29, 2022
;; Modified: December 29, 2022
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/mwang5/build-site
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(require 'package)
(require 'ox-html)
(setq package-user-dir (expand-file-name "./.packages"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install dependencies
(package-install 'htmlize)

;; load the publishing system
(require 'ox-publish)

(defvar *site-shared-directory* "content/shared")

(defvar my-website-blog-dir "./content/posts")
(defvar my-website-base-dir "./content")
(defun read-html-template (template-file)
  (with-temp-buffer
    (insert-file-contents (concat *site-shared-directory* "/" template-file))
    (buffer-string)))

(defun my-blog-get-preview (file)
  "The comments in FILE have to be on their own lines, prefereably before and after paragraphs."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((beg (+ 1 (re-search-forward "^#\\+BEGIN_PREVIEW$")))
          (end (progn (re-search-forward "^#\\+END_PREVIEW$")
                      (match-beginning 0))))
      (buffer-substring beg end))))

(defun my-blog-parse-sitemap-list (l)
  "Convert the sitemap list in to a list of filenames."
  (mapcar #'(lambda (i)
              (let ((link (with-temp-buffer
                            (let ((org-inhibit-startup nil))
                              (insert (car i))
                              (org-mode)
                              (goto-char (point-min))
                              (org-element-link-parser)))))
                (when link
                  (plist-get (cadr link) :path))))
          (cdr l)))

(defun my-blog-sort-article-list (l p)
  "sort the article list anti-chronologically."
  (sort l #'(lambda (a b)
              (let ((d-a (org-publish-find-date a p))
                    (d-b (org-publish-find-date b p)))
                (not (time-less-p d-a d-b))))))

(defun my-blog-sitemap (title list)
      "Generate the landing page for my blog."
      (with-temp-buffer
      ;; mangle the parsed list given to us into a plain lisp list of files
      (let* ((filenames (my-blog-parse-sitemap-list list))
            (project-plist (assoc "posts" org-publish-project-alist))
            (articles (my-blog-sort-article-list filenames project-plist)))
      (dolist (file filenames)
            (let* ((abspath (concat my-website-blog-dir "/" file))
                  (relpath (file-relative-name abspath my-website-base-dir))
                  (title (org-publish-find-title file project-plist))
                  (date (format-time-string (car org-time-stamp-formats) (org-publish-find-date file project-plist)))
                  (preview (my-blog-get-preview abspath)))
            ;; insert a horizontal line before every post, kill the first one
            ;; before saving
            (insert "-----\n")
            (insert (concat "* [[file:" file "][" title "]]\n"))
            ;; add properties for `ox-rss.el' here
            (let ((rss-permalink (concat (file-name-sans-extension relpath) ".html"))
                  (rss-pubdate date))
            (org-set-property "RSS_PERMALINK" rss-permalink)
            (org-set-property "PUBDATE" rss-pubdate))
            ;; insert the date, preview, & read more link
            (insert (concat "Published: " date "\n\n"))
            (insert preview)
            (insert "\n")
            (insert (concat "[[file:" file "][Read More...]]\n"))
            ))
      ;; kill the first hrule to make this look OK
      (goto-char (point-min))
      (let ((kill-whole-line t)) (kill-line))
      ;; insert a title and save
      (insert "#+OPTIONS: title:nil\n")
      (insert "#+TITLE: Blog - Michael\n")
      (insert "#+AUTHOR: Michael Wang\n")
      (insert "#+EMAIL: michael@wonng.com\n")
      (buffer-string))))

;; Customize the HTML output
(setq org-html-validation-link nil            ;; Don't show validation link
      org-html-head-include-scripts nil       ;; Use our own scripts
      org-html-head-include-default-style nil ;; Use our own styles
      org-html-head "<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\" />"
      org-html-preamble (read-html-template "nav.html")
      org-html-postamble (read-html-template "footer.html")
      )


;; Define the publishing project
(setq org-publish-project-alist
      (list
       (list "posts"
            :base-directory "./content/posts"
            :base-extension "org"
            :publishing-directory "./docs/posts"
            :publishing-function 'org-html-publish-to-html
            :auto-sitemap t
            :sitemap-function 'my-blog-sitemap
            :sitemap-title "Blog Posts"
            :sitemap-filename "index.org"
            :section-numbers nil       ;; Don't include section numbers
            :sitemap-sort-files 'anti-chronologically)
       (list "lighthouse-site"
            :recursive nil
            :base-directory "./content"
            :publishing-directory "./docs"
            :publishing-function 'org-html-publish-to-html
            :with-author nil           ;; Don't include author name
            :with-creator t            ;; Include Emacs and Org versions in footer
            :with-toc nil                ;; Include a table of contents
            :section-numbers nil       ;; Don't include section numbers
            :time-stamp-file nil    ;; Don't include time stamp in file
            :auto-sitemap t
            :sitemap-filename "sitemap.org")
            ))

;; Generate the site output
(org-publish-all t)

(message "Build complete!")

;;; build-site.el ends here