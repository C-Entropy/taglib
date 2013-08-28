;;; -*- Mode: Lisp;  show-trailing-whitespace: t; Base: 10; indent-tabs: nil; Syntax: ANSI-Common-Lisp; Package: MP4-TAG; -*-
;;; Copyright (c) 2013, Mark VandenBrink. All rights reserved.
(in-package #:mp4-tag)

;;; Abstract TAG interface
(defmethod album ((me mp4-file-stream))          (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-album+))
(defmethod album-artist ((me mp4-file-stream))   (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-album-artist+))
(defmethod artist ((me mp4-file-stream))         (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-artist+))
(defmethod comment ((me mp4-file-stream))        (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-comment+))
(defmethod composer ((me mp4-file-stream))       (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-composer+))
(defmethod copyright ((me mp4-file-stream))      (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-copyright+))
(defmethod year ((me mp4-file-stream))           (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-year+))
(defmethod encoder ((me mp4-file-stream))        (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-encoder+))
(defmethod groups ((me mp4-file-stream))         (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-groups+))
(defmethod lyrics ((me mp4-file-stream))         (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-lyrics+))
(defmethod title ((me mp4-file-stream))          (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-title+))
(defmethod writer ((me mp4-file-stream))         (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-writer+))
(defmethod compilation ((me mp4-file-stream))    (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-compilation+))
(defmethod disk  ((me mp4-file-stream))          (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-disk+))
(defmethod tempo ((me mp4-file-stream))          (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-tempo+))
(defmethod genre ((me mp4-file-stream))
  (let ((genre   (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-genre+))
        (genre-x (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-genre-x+)))
    (assert (not (and genre genre-x)))
    (cond
      (genre   (format nil "~d (~a)" genre (mp3-tag:get-id3v1-genre (1- genre))))
      (genre-x (format nil "~d (~a)" genre-x (mp3-tag:get-id3v1-genre (1- genre-x))))
      (t       "None"))))
(defmethod track ((me mp4-file-stream))
  (let ((track   (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-track+))
        (track-n (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-track-n+)))
    (assert (not (and track track-n)))
    (if track
        track
        track-n)))

(defmethod show-tags ((me mp4-file-stream) &key (raw nil))
  "Show the tags for an MP4-FILE. If RAW is non-nil, dump the DATA atoms; else show subset of DATA atoms"
  (format t "~a~%" (stream-filename me))
  (if raw
      (progn
        (mp4-atom:mp4-show-raw-tag-atoms me)
        (if (audio-info me)
          (mp4-atom:vpprint (audio-info me) t)))
      (let ((album (album me))
            (album-artist (album-artist me))
            (artist (artist me))
            (comment (comment me))
            (compilation (compilation me))
            (composer (composer me))
            (copyright (copyright me))
            (disk (disk me))
            (encoder (encoder me))
            (genre (genre me))
            (groups (groups me))
            (lyrics (lyrics me))
            (tempo (tempo me))
            (title (title me))
            (track (track me))
            (writer (writer me))
            (year (year me)))

        (if (audio-info me)
          (mp4-atom:vpprint (audio-info me) t))
        (when album (format t "~&~4talbum: ~a~%" album))
        (when album-artist (format t "~4talbum-artist: ~a~%" album-artist))
        (when artist (format t "~4tartist: ~a~%" artist))
        (when comment (format t "~4tcomment: ~a~%" comment))
        (format t "~4tcompilation: ~[no~;yes;unknown~]~%" (if compilation compilation 2))
        (when composer (format t "~4tcomposer: ~a~%" composer))
        (when copyright (format t "~4tcopyright: ~a~%" copyright))
        (when disk (format t "~4tdisk: ~a~%" disk))
        (when encoder (format t "~4tencoder: ~a~%" encoder))
        (when genre (format t "~4tgenre: ~a~%" genre))
        (when groups (format t "~4tgroups: ~a~%" groups))
        (when lyrics (format t "~4tlyrics: ~a~%" lyrics))
        (when tempo (format t "~4ttempo: ~a~%" tempo))
        (when title (format t "~4ttitle: ~a~%" title))
        (when track (format t "~4ttrack: ~a~%" track))
        (when writer (format t "~4twriter: ~a~%" writer))
        (when year (format t "~4tyear: ~a~%" year)))))
