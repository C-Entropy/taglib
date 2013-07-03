;;; -*- Mode: Lisp;  show-trailing-whitespace: t; Base: 10; indent-tabs: nil; Syntax: ANSI-Common-Lisp; Package: TAGLIB-TESTS; -*-
;;; Copyright (c) 2013, Mark VandenBrink. All rights reserved.
(in-package #:cl-user)

(defpackage #:taglib-tests
  (:use #:common-lisp #:logging))

(in-package #:taglib-tests)

(defparameter *song-m4a* "01 Keep Yourself Alive.m4a")
(defparameter *song-mp3* "02 You Take My Breath Away.mp3")

(defun set-pathname-encoding (enc)
  (setf (ccl:pathname-encoding-name) enc))
(defun set-pathname-encoding-for-osx ()
  (set-pathname-encoding :utf-8))
(defun set-pathname-encoding-for-linux ()
  (set-pathname-encoding nil))

(defmethod has-extension ((n string) ext)
  (has-extension (parse-namestring n) ext))

(defmethod has-extension ((p pathname) ext)
  (let ((e (pathname-type p)))
	(if e
	  (string= (string-downcase e) (string-downcase ext))
	  nil)))

(defmacro redirect (filename &rest body)
  `(let ((*standard-output* (open ,filename :direction :output :if-does-not-exist :create :if-exists :overwrite)))
	 ,@body))

;;;;;;;;;;;;;;;;;;;; MP4 Tests ;;;;;;;;;;;;;;;;;;;;
(defun mp4-test0 (file)
  (let (foo)
	(unwind-protect 
		 (setf foo (mp4-file:make-mp4-file file t))
	  (when foo (base-file:close-audio-file foo)))
	foo))

(defun mp4-test1 ()
  (mp4-test0 *song-m4a*))

(defun mp4-test2 (&key (dir "Queen"))
  (osicat:walk-directory dir (lambda (f)
							   (when (has-extension f "m4a")
								 (let ((file (mp4-test0 f)))
								   (when file (mp4-tag:show-tags file)))))))

;;;;;;;;;;;;;;;;;;;; MP3 Tests ;;;;;;;;;;;;;;;;;;;;
(defun mp3-test0 (file)
  (let (foo)
	(unwind-protect 
		 (setf foo (mp3-file:make-mp3-file file t))
	  (when foo (base-file:close-audio-file foo)))
	foo))

(defun mp3-test1 ()
  (mp3-test0 *song-mp3*))

(defun mp3-test2 (&key (dir "Queen"))
  (osicat:walk-directory dir (lambda (f)
							   (when (has-extension f "mp3")
								 (let ((file (mp3-test0 f)))
								   (when file (mp3-tag:show-tags file)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun test2 (&key (dir "Queen"))
  (osicat:walk-directory dir (lambda (f)
							   (if (has-extension f "mp3")
								   (let ((file (mp3-test0 f)))
									 (when file (mp3-tag:show-tags file)))
								   (if (has-extension f "m4a")
									   (let ((file (mp4-test0 f)))
										 (when file (mp4-tag:show-tags file))))))))
