;;; -*- Mode: Lisp;  show-trailing-whitespace: t; Base: 10; indent-tabs: nil; Syntax: ANSI-Common-Lisp; Package: MPEG; -*-
;;; Copyright (c) 2013, Mark VandenBrink. All rights reserved.

;;; Parsing MPEG audio frames.  See
;;; http://www.datavoyage.com/mpgscript/mpeghdr.htm for format of a frame.
(in-package #:mpeg)

(defconstant* +sync-word+  #x7ff "NB: this is 11 bits so as to be able to recognize V2.5")

;;; the versions
(defconstant* +mpeg-2.5+   0)
(defconstant* +v-reserved+ 1)
(defconstant* +mpeg-2+     2)
(defconstant* +mpeg-1+     3)

(defun valid-version (version)
  (declare #.utils:*standard-optimize-settings*)
  (or ;; can't deal with 2.5's yet (= (the fixnum +mpeg-2.5+) (the fixnum version))
      (= (the fixnum +mpeg-2+) (the fixnum version))
      (= (the fixnum +mpeg-1+) (the fixnum version))))

(defun get-mpeg-version-string (version)
  (declare #.utils:*standard-optimize-settings*)
  (nth version '("MPEG 2.5" "Reserved" "MPEG 2" "MPEG 1")))

;;; the layers
(defconstant* +layer-reserved+  0)
(defconstant* +layer-3+         1)
(defconstant* +layer-2+         2)
(defconstant* +layer-1+         3)

(defun valid-layer (layer)
  (declare #.utils:*standard-optimize-settings*)

  (or (= (the fixnum +layer-3+) (the fixnum layer))
      (= (the fixnum +layer-2+) (the fixnum layer))
      (= (the fixnum +layer-1+) (the fixnum layer))))

(defun get-layer-string (layer)
  (declare #.utils:*standard-optimize-settings*)
  (nth layer '("Reserved" "Layer III" "Layer II" "Layer I")))

;;; the modes
(defconstant* +channel-mode-stereo+ 0)
(defconstant* +channel-mode-joint+  1)
(defconstant* +channel-mode-dual+   2)
(defconstant* +channel-mode-mono+   3)

(defun get-channel-mode-string (mode)
  (declare #.utils:*standard-optimize-settings*)

  (nth mode '("Stereo" "Joint" "Dual" "Mono")))

;;; the emphases
(defconstant* +emphasis-none+     0)
(defconstant* +emphasis-50-15+    1)
(defconstant* +emphasis-reserved+ 2)
(defconstant* +emphasis-ccit+     3)

(defun get-emphasis-string (e)
  (declare #.utils:*standard-optimize-settings*)

  (nth e '("None" "50/15 ms" "Reserved" "CCIT J.17")))

(defun valid-emphasis (e)
  (declare #.utils:*standard-optimize-settings*)

  (or (= (the fixnum e) (the fixnum +emphasis-none+))
      (= (the fixnum e) (the fixnum +emphasis-50-15+))
      (= (the fixnum e) (the fixnum +emphasis-ccit+))))

;;; the modes
(defconstant* +mode-extension-0+ 0)
(defconstant* +mode-extension-1+ 1)
(defconstant* +mode-extension-2+ 2)
(defconstant* +mode-extension-3+ 3)

(defun get-mode-extension-string (channel-mode layer mode-extension)
  (declare #.utils:*standard-optimize-settings*)

  (if (not (= channel-mode +channel-mode-joint+))
      ""
      (if (or (= layer +layer-1+)
              (= layer +layer-2+))
          (format nil "Bands ~[4~;8~;12~;16~] to 31" mode-extension)
          (format nil "Intensity Stereo: ~[off~;on~], MS Stereo: ~[off~;on~]"
                  (ash mode-extension -1) (logand mode-extension 1)))))

(defun get-samples-per-frame (version layer)
  (declare #.utils:*standard-optimize-settings*)

  (cond ((= (the fixnum layer) (the fixnum +layer-1+)) 384)
        ((= (the fixnum layer) (the fixnum +layer-2+)) 1152)
        ((= (the fixnum layer) (the fixnum +layer-3+))
         (cond ((= (the fixnum version) +mpeg-1+) 1152)
               ((or (= (the fixnum version) (the fixnum +mpeg-2+))
                    (= (the fixnum version) (the fixnum +mpeg-2.5+))) 576)))))

(defclass frame ()
  ((pos            :accessor pos            :initarg :pos)
   (hdr-u32        :accessor hdr-u32        :initarg :hdr-u32)
   (samples        :accessor samples        :initarg :samples)
   (sync           :accessor sync           :initarg :sync)
   (version        :accessor version        :initarg :version)
   (layer          :accessor layer          :initarg :layer)
   (protection     :accessor protection     :initarg :protection)
   (bit-rate       :accessor bit-rate       :initarg :bit-rate)
   (sample-rate    :accessor sample-rate    :initarg :sample-rate)
   (padded         :accessor padded         :initarg :padded)
   (private        :accessor private        :initarg :private)
   (channel-mode   :accessor channel-mode   :initarg :channel-mode)
   (mode-extension :accessor mode-extension :initarg :mode-extension)
   (copyright      :accessor copyright      :initarg :copyright)
   (original       :accessor original       :initarg :original)
   (emphasis       :accessor emphasis       :initarg :emphasis)
   (size           :accessor size           :initarg :size)
   (vbr            :accessor vbr            :initarg :vbr)
   (payload        :accessor payload        :initarg :payload))
  (:documentation "Data in and associated with an MPEG audio frame.")
  (:default-initargs :pos nil :hdr-u32 nil :samples 0 :sync 0 :version 0
                     :layer 0 :protection 0 :bit-rate 0
                     :sample-rate 0 :padded 0 :private 0 :channel-mode 0
                     :mode-extension 0
                     :copyright 0 :original 0 :emphasis 0 :size nil :vbr nil
                     :payload nil))

(defmacro with-frame-slots ((instance) &body body)
  `(with-slots (pos hdr-u32 samples sync version layer protection bit-rate sample-rate
                padded private channel-mode mode-extension copyright
                original emphasis size vbr payload) ,instance
     ,@body))

(let ((bit-array-table
       (make-array '(14 5) :initial-contents
                   '((32   32  32  32   8)
                     (64   48  40  48  16)
                     (96   56  48  56  24)
                     (128  64  56  64  32)
                     (160  80  64  80  40)
                     (192  96  80  96  48)
                     (224 112  96 112  56)
                     (256 128 112 128  64)
                     (288 160 128 144  80)
                     (320 192 160 160  96)
                     (352 224 192 176 112)
                     (384 256 224 192 128)
                     (416 320 256 224 144)
                     (448 384 320 256 160)))))

  (defun valid-bit-rate-index (br-index)
    (declare #.utils:*standard-optimize-settings*)

    (and (> (the fixnum br-index) 0) (< (the fixnum br-index) 15)))

  (defun get-bit-rate (version layer bit-rate-index)
    (declare #.utils:*standard-optimize-settings*)

    (let ((row (1- bit-rate-index))
          (col (cond ((= (the fixnum version) (the fixnum +mpeg-1+))
                      (cond ((= (the fixnum layer) (the fixnum +layer-1+)) 0)
                            ((= (the fixnum layer) (the fixnum +layer-2+)) 1)
                            ((= (the fixnum layer) (the fixnum +layer-3+)) 2)
                            (t nil)))
                     ((= (the fixnum version) (the fixnum +mpeg-2+))
                      (cond ((= (the fixnum layer) (the fixnum +layer-1+)) 3)
                            ((= (the fixnum layer) (the fixnum +layer-2+)) 4)
                            ((= (the fixnum layer) (the fixnum +layer-3+)) 4)
                            (t nil)))
                     (t (error "don't support MPEG 2.5 yet")))))

      (if (or (null col) (< row 0) (> row 14))
          nil
          (* 1000 (aref bit-array-table row col))))))

(defun valid-sample-rate-index (sr-index)
  (declare #.utils:*standard-optimize-settings*)

  (and (>= (the fixnum sr-index) 0)
       (<  (the fixnum sr-index) 3)))

(defun get-sample-rate (version sr-index)
  (declare #.utils:*standard-optimize-settings*)

  (cond ((= (the fixnum version) (the fixnum +mpeg-1+))
         (case (the fixnum sr-index) (0 44100) (1 48000) (2 32000)))
        ((= (the fixnum version) (the fixnum +mpeg-2+))
         (case (the fixnum sr-index) (0 22050) (1 24000) (2 16000)))
        (t nil)))

(defun get-frame-size (version layer bit-rate sample-rate padded)
  (declare #.utils:*standard-optimize-settings*)

  (truncate (float (cond ((= (the fixnum layer) (the fixnum +layer-1+))
                          (* 4 (+ (/ (* 12 bit-rate) sample-rate) padded)))
                         ((= (the fixnum layer) (the fixnum +layer-2+))
                          (+ (* 144 (/ bit-rate sample-rate)) padded))
                         ((= (the fixnum layer) (the fixnum +layer-3+))
                          (if (= (the fixnum version) (the fixnum +mpeg-1+))
                              (+ (* 144 (/ bit-rate sample-rate)) padded)
                              (+ (* 72  (/ bit-rate sample-rate)) padded)))))))

(defmethod load-frame ((me frame) &key instream (read-payload nil))
  "Load an MPEG frame from current file position.  If READ-PAYLOAD is set,
read in frame's content."
  (declare #.utils:*standard-optimize-settings*)

  (handler-case
      (with-frame-slots (me)
        (when (null hdr-u32)            ; has header already been read in?
          (setf pos     (stream-seek instream)
                hdr-u32 (stream-read-u32 instream))
          (when (null hdr-u32)
            (return-from load-frame nil)))

        (if (parse-header me)
            (progn
              (setf size (get-frame-size version layer bit-rate sample-rate
                                         padded))
              (when read-payload
                (setf payload (stream-read-sequence instream (- size 4))))
              t)
            nil))
    (end-of-file (c)
      (declare (ignore c))
      nil)))

(defmethod parse-header ((me frame))
  "Given a frame, verify that is a valid MPEG audio frame by examining the header.
A header looks like this:
Bits 31-21 (11 bits): the sync word.  Must be #xffe (NB version 2.5 standard)
Bits 20-19 (2  bits): the version
Bits 18-17 (2  bits): the layer
Bit     16 (1  bit ): the protection bit
Bits 15-12 (4  bits): the bit-rate index
Bits 11-10 (2  bits): the sample-rate index
Bit      9 (1  bit ): the padding bit
Bit      8 (1  bit ): the private bit
Bits   7-6 (2  bits): the channel mode
Bits   5-4 (2  bits): the mode extension
Bit      3 (1  bit ): the copyright bit
Bit      2 (1  bit ): the original bit
Bits   1-0 (2  bits): the emphasis"
  (declare #.utils:*standard-optimize-settings*)

  (with-frame-slots (me)
    ;; check sync word
    (setf sync (get-bitfield hdr-u32 31 11))
    (when (not (= sync +sync-word+))
      (return-from parse-header nil))

    ;; check version
    (setf version (get-bitfield hdr-u32 20 2))
    (when (not (valid-version version))
      (return-from parse-header nil))

    ;; check layer
    (setf layer (get-bitfield hdr-u32 18 2))
    (when (not (valid-layer layer))
      (return-from parse-header nil))

    (setf protection (get-bitfield hdr-u32 16 1)
          samples (get-samples-per-frame version layer))

    ;; check bit-rate
    (let ((br-index (get-bitfield hdr-u32 15 4)))
      (when (not (valid-bit-rate-index br-index))
        (return-from parse-header nil))

      (setf bit-rate (get-bit-rate version layer br-index)))

    ;; check sample rate
    (let ((sr-index (get-bitfield hdr-u32 11 2)))
      (when (not (valid-sample-rate-index sr-index))
        (return-from parse-header nil))

      (setf sample-rate (get-sample-rate version sr-index)))

    (setf padded         (get-bitfield hdr-u32 9 1)
          private        (get-bitfield hdr-u32 8 1)
          channel-mode   (get-bitfield hdr-u32 7 2)
          mode-extension (get-bitfield hdr-u32 5 2)
          copyright      (get-bitfield hdr-u32 3 1)
          original       (get-bitfield hdr-u32 2 1)
          emphasis       (get-bitfield hdr-u32 1 2))

    ;; check emphasis
    (when (not (valid-emphasis emphasis))
      (return-from parse-header nil))

    t))

(defmethod vpprint ((me frame) stream)
  (format stream "~a"
          (with-output-to-string (s)
            (with-frame-slots (me)
              (format s "MPEG Frame: position in file = ~:d, header in (hex) bytes = ~x, size = ~d, sync word = ~x, " pos hdr-u32 size sync)
              (when vbr
                (format s "~&vbr-info: ~a~%" vbr))
              (format s "version = ~a, layer = ~a, crc protected? = ~[yes~;no~], bit-rate = ~:d bps, sampling rate = ~:d bps, padded? = ~[no~;yes~], private bit set? = ~[no~;yes~], channel mode = ~a, "
                      (get-mpeg-version-string version) (get-layer-string layer)
                      protection bit-rate sample-rate padded private (get-channel-mode-string channel-mode))
              (format s "mode extension = ~a, copyrighted? = ~[no~;yes~], original? = ~[no~;yes~], emphasis = ~a"
                      (get-mode-extension-string channel-mode layer mode-extension) copyright original (get-emphasis-string emphasis))
              (when payload
                (format s "~%frame payload[~:d] = ~a~%" (length payload) (utils:printable-array payload)))))))

(defclass vbr-info ()
  ((tag    :accessor tag    :initarg :tag)
   (flags  :accessor flags  :initarg :flags)
   (frames :accessor frames :initarg :frames)
   (bytes  :accessor bytes  :initarg :bytes)
   (tocs   :accessor tocs   :initarg :tocs)
   (scale  :accessor scale  :initarg :scale))
  (:default-initargs :tag nil :flags 0 :frames nil :bytes nil :tocs nil :scale nil))

(defmacro with-vbr-info-slots ((instance) &body body)
  `(with-slots (tag flags frames bytes tocs scale) ,instance
     ,@body))

(defconstant* +vbr-frames+  1)
(defconstant* +vbr-bytes+   2)
(defconstant* +vbr-tocs+    4)
(defconstant* +vbr-scale+   8)

(defun get-side-info-size (version channel-mode)
  (declare #.utils:*standard-optimize-settings*)

  (cond ((= (the fixnum version) (the fixnum +mpeg-1+))
         (cond ((= (the fixnum channel-mode) (the fixnum +channel-mode-mono+)) 17)
               (t 32)))
        (t (cond ((= (the fixnum channel-mode) (the fixnum +channel-mode-mono+)) 9)
                 (t 17)))))

(defmethod check-vbr ((me frame))
  (declare #.utils:*standard-optimize-settings*)

  (with-frame-slots (me)
    (let ((i (get-side-info-size version channel-mode)))
      (when (>= i (length payload))
        (return-from check-vbr nil))

      (when (or (and (= (aref payload (+ i 0)) (char-code #\X))
                     (= (aref payload (+ i 1)) (char-code #\i))
                     (= (aref payload (+ i 2)) (char-code #\n))
                     (= (aref payload (+ i 3)) (char-code #\g)))
                (and (= (aref payload (+ i 0)) (char-code #\I))
                     (= (aref payload (+ i 1)) (char-code #\n))
                     (= (aref payload (+ i 2)) (char-code #\f))
                     (= (aref payload (+ i 3)) (char-code #\o))))

        (setf vbr (make-instance 'vbr-info))
        (let ((v (make-audio-stream (payload me))))
          (stream-seek v i :start)      ; seek to Xing/Info offset
          (setf (tag vbr)   (stream-read-iso-string v 4)
                (flags vbr) (stream-read-u32 v))

          (when (logand (flags vbr) +vbr-frames+)
            (setf (frames vbr) (stream-read-u32 v)))

          (when (logand (flags vbr) +vbr-bytes+)
            (setf (bytes vbr) (stream-read-u32 v)))

          (when (logand (flags vbr) +vbr-tocs+)
            (setf (tocs vbr) (stream-read-sequence v 100)))

          (when (logand (flags vbr) +vbr-scale+)
            (setf (scale vbr) (stream-read-u32 v))))))))

(defmethod vpprint ((me vbr-info) stream)
  (with-vbr-info-slots (me)
    (format stream "tag = ~a, flags = 0x~x, frame~p = ~:d, bytes = ~:d, tocs = ~d, scale = ~d, "
            tag flags frames frames bytes tocs scale)))

(defun find-first-sync (instream)
  "Scan the file looking for the first sync word."
  (declare #.utils:*standard-optimize-settings*)

  (let ((hdr-u32)
        (count 0)
        (pos))

    (handler-case
        (loop
          (setf pos     (stream-seek instream)
                hdr-u32 (stream-read-u32 instream))
          (when (null hdr-u32)
            (return-from find-first-sync nil))
          (incf count)

          (when (= (logand hdr-u32 #xffe00000) #xffe00000) ; magic number is potential sync frame header
            (let ((hdr (make-instance 'frame :hdr-u32 hdr-u32 :pos pos)))
              (if (load-frame hdr :instream instream :read-payload t)
                  (progn
                    (check-vbr hdr)
                    (return-from find-first-sync hdr))))))
      (condition (c) (progn
                       (warn-user "file:~a~%Condtion <~a> signaled while looking for first sync"
                                  audio-streams:*current-file* c)
                       (error c))))
    nil))

(defmethod next-frame ((me frame) &key instream read-payload)
  "Get next frame.  If READ-PAYLOAD is true, read in contents for frame, else, seek to next frame header."
  (declare #.utils:*standard-optimize-settings*)

  (let ((nxt-frame (make-instance 'frame)))
    (when (not (payload me))
      (stream-seek instream (- (size me) 4) :current))

    (if (load-frame nxt-frame :instream instream :read-payload read-payload)
        nxt-frame
        nil)))

(defparameter *max-frames-to-read* most-positive-fixnum "when trying to determine bit-rate, etc, read at most this many frames")

(defun map-frames (in func &key (start-pos nil) (read-payload nil) (max nil))
  "Loop through the MPEG audio frames in a file.  If *MAX-FRAMES-TO-READ*
is set, return after reading that many frames."
  (declare #.utils:*standard-optimize-settings*)

  (when start-pos
    (stream-seek in start-pos :start))

    (loop
      for max-frames = (if max max *max-frames-to-read*)
      for count = 0 then (incf count)
      for frame = (find-first-sync in) then (next-frame frame :instream in :read-payload read-payload)
      while (and frame (< count max-frames)) do
        (funcall func frame)))

(defclass mpeg-audio-info ()
  ((is-vbr      :accessor is-vbr      :initarg :is-vbr      :initform nil)
   (n-frames    :accessor n-frames    :initarg :n-frames    :initform 0)
   (bit-rate    :accessor bit-rate    :initarg :bit-rate    :initform nil)
   (sample-rate :accessor sample-rate :initarg :sample-rate :initform nil)
   (len         :accessor len         :initarg :len         :initform nil)
   (version     :accessor version     :initarg :version     :initform nil)
   (layer       :accessor layer       :initarg :layer       :initform nil)))

(defmethod vpprint ((me mpeg-audio-info) stream)
  (with-slots (is-vbr sample-rate bit-rate len version layer n-frames) me
    (format stream "~:d frame~p read, ~a, ~a, ~:[CBR,~;VBR,~] sample rate: ~:d Hz, bit rate: ~:d Kbps, duration: ~:d:~2,'0d"
            n-frames n-frames
            (get-mpeg-version-string version)
            (get-layer-string layer)
            is-vbr
            sample-rate
            (round (/ bit-rate 1000))
            (floor (/ len 60)) (round (mod len 60)))))

(defun calc-bit-rate-exhaustive (instream start info)
  "Map every MPEG frame in INSTREAM and calculate the bit-rate"
  (declare #.utils:*standard-optimize-settings*)

  (let ((total-len      0)
        (bit-rate-total 0))

    (with-slots (is-vbr sample-rate bit-rate len version layer n-frames) info
      (map-frames instream (lambda (f)
                             (incf n-frames)
                             (incf total-len (float (/ (samples f) (sample-rate f))))
                             (incf bit-rate-total (bit-rate f)))
                  :read-payload nil :start-pos start)

      (when (or (< n-frames 10) (zerop bit-rate-total))
        (return-from calc-bit-rate-exhaustive))

      (setf is-vbr   t
            len      total-len
            bit-rate (float (/ bit-rate-total n-frames))))))

(defun get-mpeg-audio-info (instream mp3-file)
  "Get MPEG Layer 3 audio information.
 If the first MPEG frame we find is a Xing/Info header, return that as info.
 Else, we assume CBR and calculate the duration, etc."
  (declare #.utils:*standard-optimize-settings*)

  (let ((first-frame (find-first-sync instream))
        (info        (make-instance 'mpeg-audio-info)))

    (when (null first-frame)
      (return-from get-mpeg-audio-info))

    (with-slots (is-vbr sample-rate bit-rate len version layer n-frames) info
      (setf version     (version first-frame)
            layer       (layer first-frame)
            sample-rate (sample-rate first-frame))

      (if (vbr first-frame)
          ;; found a Xing header, now check to see if it is correct
          (if (zerop (frames (vbr first-frame)))
              (progn
                ;; Xing header broken, read all frames to calc
                (warn-user
                 "file ~a:~%Xing/Info header has FRAMES set, but field is zero."
                 audio-streams:*current-file*)
                (calc-bit-rate-exhaustive instream (pos first-frame) info))

              ;; else, good Xing header, use info in VBR to calc
              (setf n-frames 1
                    is-vbr   t
                    len      (float (* (frames (vbr first-frame))
                                       (/ (samples first-frame)
                                          (sample-rate first-frame))))
                    bit-rate (float (/ (* 8 (bytes (vbr first-frame))) len))))

          ;; No Xing header found. Assume CBR and calculate based on first frame
          (let* ((first (pos first-frame))
                 (last (- (stream-size instream)
                          (if (id3:v21-tag-header
                               (id3:id3-header mp3-file)) 128 0)))
                 (n-fr (round (/ (float (- last first))
                                 (float (size first-frame)))))
                 (n-sec (round (/ (float (* (size first-frame) n-fr))
                                  (float (* 125 (float
                                                 (/ (bit-rate first-frame) 1000))))))))
            (setf is-vbr   nil
                  n-frames 1
                  len      n-sec
                  bit-rate (float (bit-rate first-frame))))))
    (setf (id3:audio-info mp3-file) info)))
