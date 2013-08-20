;;; -*- Mode: Lisp;  show-trailing-whitespace: t; Base: 10; indent-tabs: nil; Syntax: ANSI-Common-Lisp; Package: UTILS; -*-
;;; Copyright (c) 2013, Mark VandenBrink. All rights reserved.
(in-package #:utils)

(defun warn-user (format-string &rest args)
  "print a warning error to *ERROR-OUTPUT* and continue"
  ;; COMPLETELY UNPORTABLE!!!
  (format *error-output* "~&~&WARNING in ~a:: " (ccl::%last-fn-on-stack 1))
  (apply #'format *error-output* format-string args)
  (format *error-output* "~%~%"))

(defparameter *max-raw-bytes-print-len* 10)

(defun printable-array (array)
  "given an array, return a string of the first *MAX-RAW-BYTES-PRINT-LEN* bytes"
  (let* ((len (length array))
         (print-len (min len *max-raw-bytes-print-len*))
         (printable-array (make-array print-len :displaced-to array)))
    (format nil "[~:d of ~:d bytes] <~x>" print-len len printable-array)))

(defun upto-null (string)
  "Trim STRING to end at first NULL found"
  (subseq string 0 (position #\Null string)))

(defun dump-data (file-name data)
  (with-open-file (f file-name :direction :output :if-exists :supersede :element-type '(unsigned-byte 8))
    (write-sequence data f)))