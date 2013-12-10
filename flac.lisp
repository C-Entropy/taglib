;;; -*- Mode: Lisp;  show-trailing-whitespace: t; Base: 10; indent-tabs: nil; Syntax: ANSI-Common-Lisp; Package: FLAC; -*-
;;; Copyright (c) 2013, Mark VandenBrink. All rights reserved.
(in-package #:flac)

;;; FLAC header types
(defconstant* +metadata-streaminfo+  0)
(defconstant* +metadata-padding+     1)
(defconstant* +metadata-application+ 2)
(defconstant* +metadata-seektable+   3)
(defconstant* +metadata-comment+     4)
(defconstant* +metadata-cuesheet+    5)
(defconstant* +metadata-picture+     6)

(defclass flac-header ()
  ((pos         :accessor pos         :initarg :pos
                :documentation "file location of this flac header")
   (last-bit    :accessor last-bit    :initarg :last-bit
                :documentation "if set, this is the last flac header in file")
   (header-type :accessor header-type :initarg :header-type
                :documentation "one of the flac header types above")
   (header-len  :accessor header-len  :initarg :header-len
                :documentation "how long the info associated w/header is"))
  (:documentation "Representation of FLAC stream header"))

(defmacro with-flac-slots ((instance) &body body)
  `(with-slots (pos last-bit header-type header-len) ,instance
     ,@body))

(defmethod vpprint ((me flac-header) stream)
  (with-flac-slots (me)
    (format stream "pos = ~:d, last-bit = ~b, header-type = ~d, length = ~:d"
            pos
            last-bit
            header-type
            header-len)))

(defun is-valid-flac-file (flac-file)
  "Make sure this is a FLAC file. Look for FLAC header at begining"
  (declare #.utils:*standard-optimize-settings*)

  (stream-seek flac-file 0 :start)

  (let ((valid nil))
    (when (> (stream-size flac-file) 4)
      (let ((hdr (stream-read-iso-string flac-file 4)))
        (setf valid (string= "fLaC" hdr))))
    (stream-seek flac-file 0 :start)
    valid))

(defun make-flac-header (stream)
  "Make a flac header from current position in stream"
  (declare #.utils:*standard-optimize-settings*)

  (let* ((header (stream-read-u32 stream))
         (flac-header (make-instance 'flac-header
                                     :pos (- (stream-seek stream) 4)
                                     :last-bit (utils:get-bitfield header 31 1)
                                     :header-type (utils:get-bitfield header 30 7)
                                     :header-len (utils:get-bitfield header 23 24))))
    flac-header))


(defparameter *flac-tag-pattern*
  "(^[a-zA-Z]+)=(.*$)" "regex used to parse FLAC/ORBIS comments")

(defclass flac-tags ()
  ((vendor-str :accessor vendor-str :initarg :vendor-str :initform nil)
   (comments   :accessor comments   :initarg :comments   :initform nil)
   (tags       :accessor tags                            :initform (make-hash-table :test 'equal))))

(defmethod flac-add-tag ((me flac-tags) new-tag new-val)
  (declare #.utils:*standard-optimize-settings*)

  (let ((l-new-tag (string-downcase new-tag)))
    (setf (gethash l-new-tag (tags me)) new-val)))

(defmethod flac-get-tag ((me flac-tags) key)
  (declare #.utils:*standard-optimize-settings*)

  (gethash (string-downcase key) (tags me)))

(defun flac-get-tags (stream)
  "Loop through file and find all comment tags."
  (declare #.utils:*standard-optimize-settings*)

  (let* ((tags (make-instance 'flac-tags))
         (vendor-len (stream-read-u32 stream :endian :big-endian))
         (vendor-str (stream-read-utf-8-string stream vendor-len))
         (lst-len (stream-read-u32 stream :endian :big-endian)))

    (setf (vendor-str tags) vendor-str)

    (dotimes (i lst-len)
      (let* ((comment-len (stream-read-u32 stream :endian :big-endian))
             (comment (stream-read-utf-8-string stream comment-len)))
        (push comment (comments tags))
        (optima:match comment ((optima.ppcre:ppcre *flac-tag-pattern* tag value)
                               (flac-add-tag tags tag value)))))
    (setf (comments tags) (nreverse (comments tags)))
    tags))

(defclass flac-file ()
  ((filename     :accessor filename :initform nil :initarg :filename
                 :documentation "filename that was parsed")
   (flac-headers :accessor flac-headers :initform nil
                 :documentation "holds all the flac headers in file")
   (audio-info   :accessor audio-info   :initform nil
                 :documentation "parsed audio info")
   (flac-tags    :accessor flac-tags    :initform nil
                 :documentation "parsed comment tags."))
  (:documentation "Stream for parsing flac files"))

(defun parse-audio-file (instream &optional (get-audio-info nil))
  "Loop through file and find all FLAC headers. If we find comment or audio-info
headers, go ahead and parse them too."
  (declare #.utils:*standard-optimize-settings*)
  (declare (ignore get-audio-info)) ; audio info comes for "free"

  (stream-seek instream 4 :start)

  (let ((parsed-info (make-instance 'flac-file
                                    :filename (stream-filename instream))))
    (let (headers)
      (loop for h = (make-flac-header instream)
              then (make-flac-header instream) do
                (push h headers)
                (cond
                  ((= +metadata-comment+ (header-type h))
                   (setf (flac-tags parsed-info) (flac-get-tags instream)))
                  ((= +metadata-streaminfo+ (header-type h))
                   (setf (audio-info parsed-info) (get-flac-audio-info instream)))
                  (t (stream-seek instream (header-len h) :current)))
                (when (not (zerop (last-bit h)))
                  (return)))
      (setf (flac-headers parsed-info) (nreverse headers)))
    parsed-info))

(defclass flac-audio-properties ()
  ((min-block-size  :accessor min-block-size  :initarg :min-block-size  :initform 0)
   (max-block-size  :accessor max-block-size  :initarg :max-block-size  :initform 0)
   (min-frame-size  :accessor min-frame-size  :initarg :min-frame-size  :initform 0)
   (max-frame-size  :accessor max-frame-size  :initarg :max-frame-size  :initform 0)
   (sample-rate     :accessor sample-rate     :initarg :sample-rate     :initform 0)
   (num-channels    :accessor num-channels    :initarg :num-channels    :initform 0)
   (bits-per-sample :accessor bits-per-sample :initarg :bits-per-sample :initform 0)
   (total-samples   :accessor total-samples   :initarg :total-samples   :initform 0)
   (md5-sig         :accessor md5-sig         :initarg :md5-sig         :initform 0))
  (:documentation "FLAC audio file properties"))

(defmethod vpprint ((me flac-audio-properties) stream)
  (format stream
          "min/max block size: ~:d/~:d; min/max frame size: ~:d/~:d; sample rate: ~d Hz; # channels: ~d; bps: ~:d; total-samples: ~:d; sig: ~x"
          (min-block-size me) (max-block-size me)
          (min-frame-size me) (max-frame-size me)
          (sample-rate me) (num-channels me) (bits-per-sample me)
          (total-samples me) (md5-sig me)))

(defun get-flac-audio-info (flac-stream)
  "Read in the the audio properties from current file position."
  (declare #.utils:*standard-optimize-settings*)

  (let ((info (make-instance 'flac-audio-properties)))
    (setf (min-block-size info) (stream-read-u16 flac-stream)
          (max-block-size info) (stream-read-u16 flac-stream)
          (min-frame-size info) (stream-read-u24 flac-stream)
          (max-frame-size info) (stream-read-u24 flac-stream))
    (let* ((int1 (stream-read-u32 flac-stream))
           (int2 (stream-read-u32 flac-stream)))
      (setf (total-samples info)   (logior (ash (get-bitfield int1 3  4) -32) int2)
            (bits-per-sample info) (1+ (get-bitfield int1 8  5))
            (num-channels info)    (1+ (get-bitfield int1 11 3))
            (sample-rate info)     (get-bitfield int1 31 20)
            (md5-sig info)         (stream-read-u128 flac-stream)))
    info))

(defun flac-show-raw-tag (flac-file-stream out-stream)
  "Spit out the raw form of comments we found"
  (declare #.utils:*standard-optimize-settings*)

  (format out-stream "Vendor string: <~a>~%" (vendor-str (flac-tags flac-file-stream)))
  (dotimes (i (length (comments (flac-tags flac-file-stream))))
    (format out-stream "~4t[~d]: <~a>~%" i (nth i (comments (flac-tags flac-file-stream))))))
