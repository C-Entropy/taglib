;;; -*- Mode: Lisp;  show-trailing-whitespace: t; Base: 10; indent-tabs: nil; Syntax: ANSI-Common-Lisp; Package: TAGLIB-TESTS; -*-
;;; Copyright (c) 2013, Mark VandenBrink. All rights reserved.
(in-package #:cl-user)

(defpackage #:taglib-tests
  (:use #:common-lisp #:logging #:audio-streams))

(in-package #:taglib-tests)

(defparameter *song-m4a* "01 Keep Yourself Alive.m4a"     "handy filename to test MP4s")
(defparameter *song-mp3* "02 You Take My Breath Away.mp3" "handy filename to test MP3s")

(defun report-error (format-string &rest args)
  "Used in the mpX-testX functions below to show errors found to user."
  (format *error-output* "~&****************************************~%")
  (apply #'format *error-output* format-string args)
  (format *error-output* "****************************************~%"))

;;;
;;; Set the pathname (aka filename) encoding in CCL for appropriate platorm
(defun set-pathname-encoding (enc)        (setf (ccl:pathname-encoding-name) enc))
(defun set-pathname-encoding-for-osx ()   (set-pathname-encoding :utf-8))
(defun set-pathname-encoding-for-linux () (set-pathname-encoding nil))

(defmethod has-extension ((n string) ext)
  "Probably should use CL's PATHNAME methods, but simply looking at the .XXX portion of a filename
to see if it matches. This is the string version that makes a PATHNAME and calls the PATHNAME version."
  (has-extension (parse-namestring n) ext))

(defmethod has-extension ((p pathname) ext)
  "Probably should use CL's PATHNAME methods , but simply looking at the .XXX portion of a filename
to see if it matches. PATHNAME version."
  (let ((e (pathname-type p)))
    (if e
      (string= (string-downcase e) (string-downcase ext))
      nil)))

(defmacro redirect (filename &rest body)
  "Temporarily set *STANDARD-OUTPUT* to FILENAME and execute BODY."
  `(let ((*standard-output* (open ,filename :direction :output :if-does-not-exist :create :if-exists :supersede)))
     ,@body
     (finish-output *standard-output*)))

;;; A note re filesystem encoding: my music collection is housed on a Mac and shared via SAMBA.
;;; In order to make sure we get valid pathnames, we need to set CCL's filesystem encoding to
;;; :UTF-8

;;;;;;;;;;;;;;;;;;;; MP4 Tests ;;;;;;;;;;;;;;;;;;;;
(defun mp4-test0 (file)
  "Parse one MP3 file (with condition handling)."
  (let ((dir (ccl:current-directory))
        (foo))
    (unwind-protect
         (handler-case
             (setf foo (parse-mp4-file file))
           (condition (c)
             (report-error "Dir: ~a~%File: ~a~%Got condition: <~a>~%" dir file c)))
      (when foo (stream-close foo)))
    foo))

(defun mp4-test1 ()
  (mp4-test0 *song-m4a*))

(defun mp4-test2 (&key (dir "Queen") (raw nil) (file-system-encoding :utf-8))
  "Walk :DIR and call SHOW-TAGS for each file (MP4/MP3) found."
  (set-pathname-encoding file-system-encoding)
  (osicat:walk-directory dir (lambda (f)
                               (when (has-extension f "m4a")
                                 (let ((file (mp4-test0 f)))
                                   (when file
                                     (mp4-tag:show-tags file :raw raw)
                                     (mp4-atom::get-mp4-audio-info file)))))))

;;;;;;;;;;;;;;;;;;;; MP3 Tests ;;;;;;;;;;;;;;;;;;;;
(defun mp3-test0 (file)
  "Parse one MP3 file (with condition handling)."
  (let ((dir (ccl:current-directory))
        (foo))
    (unwind-protect
         (handler-case
             (setf foo (parse-mp3-file file))
           (condition (c)
             (report-error "Dir: ~a~%File: ~a~%Got condition: <~a>~%" dir file c)))
      (when foo (stream-close foo)))
    foo))

(defun mp3-test1 ()
  (mp3-test0 *song-mp3*))

(defun mp3-test2 (&key (dir "Queen") (raw nil) (file-system-encoding :utf-8))
  "Walk :DIR and parse every MP3 we find."
  (set-pathname-encoding file-system-encoding)
  (osicat:walk-directory dir (lambda (f)
                               (when (has-extension f "mp3")
                                 (let ((file (mp3-test0 f)))
                                   (when file (mp3-tag:show-tags file :raw raw)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun test2 (&key (dir "Queen") (raw nil) (file-system-encoding :utf-8))
  "Walk :DIR and call SHOW-TAGS for each file (MP4/MP3) found."
  (set-pathname-encoding file-system-encoding)
  (osicat:walk-directory dir (lambda (f)
                               (if (has-extension f "mp3")
                                   (let ((file (mp3-test0 f)))
                                     (when file (mp3-tag:show-tags file :raw raw)))
                                   (if (has-extension f "m4a")
                                       (let ((file (mp4-test0 f)))
                                         (when file (mp4-tag:show-tags file :raw raw))))))))
