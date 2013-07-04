;;; -*- Mode: Lisp;  show-trailing-whitespace: t; Base: 10; indent-tabs: nil; Syntax: ANSI-Common-Lisp; Package: MP4-TAG; -*-
;;; Copyright (c) 2013, Mark VandenBrink. All rights reserved.
(in-package #:mp4-tag)

(defmethod album ((me mp4-stream))          (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-album+))
(defmethod album-artist ((me mp4-stream))   (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-album-artist+))
(defmethod artist ((me mp4-stream))         (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-artist+))
(defmethod comment ((me mp4-stream))        (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-comment+))
(defmethod composer ((me mp4-stream))       (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-composer+))
(defmethod copyright ((me mp4-stream))      (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-copyright+))
(defmethod year ((me mp4-stream))           (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-year+))
(defmethod encoder ((me mp4-stream))        (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-encoder+))
(defmethod groups ((me mp4-stream))         (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-groups+))
(defmethod lyrics ((me mp4-stream))         (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-lyrics+))
(defmethod purchased-date ((me mp4-stream)) (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-purchased-date+))
(defmethod title ((me mp4-stream))          (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-title+))
(defmethod tool ((me mp4-stream))           (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-tool+))
(defmethod writer ((me mp4-stream))         (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-writer+))

(defmethod compilation ((me mp4-stream))    (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-compilation+))
(defmethod disk  ((me mp4-stream))          (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-disk+))
(defmethod tempo ((me mp4-stream))          (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-tempo+))
(defmethod genre ((me mp4-stream))
  (let ((genre   (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-genre+))
		(genre-x (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-genre-x+)))
	(assert (not (and genre genre-x)))
	(cond
	  (genre (tag:get-genre-text genre))
	  (genre-x (tag:get-genre-text genre-x))
	  (t nil))))

(defmethod track ((me mp4-stream))
  (let ((track   (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-track+))
		(track-n (mp4-atom:tag-get-value (mp4-atoms me) mp4-atom:+itunes-track-n+)))
	(assert (not (and track track-n)))
	(if track
		track
		track-n)))

(defmethod show-tags ((me mp4-stream))
  "Show the understood tags for MP4-FILE"
  (format t "~a~%" (filename me))
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
		(purchased-date (purchased-date me))
		(tempo (tempo me))
		(title (title me))
		(tool (tool me))
		(track (track me))
		(writer (writer me))
		(year (year me)))
	(when album (format t "~4talbum: ~a~%" album))
	(when album-artist (format t "~4talbum-artist: ~a~%" album-artist))
	(when artist (format t "~4tartist: ~a~%" artist))
	(when comment (format t "~4tcomment: ~a~%" comment))
	(format t "~4tcompilation: ~a~%" compilation)
	(when composer (format t "~4tcomposer: ~a~%" composer))
	(when copyright (format t "~4tcopyright: ~a~%" copyright))
	(when disk (format t "~4tdisk: ~a~%" disk))
	(when encoder (format t "~4tencoder: ~a~%" encoder))
	(when genre (format t "~4tgenre: ~a~%" genre))
	(when groups (format t "~4tgroups: ~a~%" groups))
	(when lyrics (format t "~4tlyrics: ~a~%" lyrics))
	(when purchased-date (format t "~4tpurchased date: ~a~%" purchased-date))
	(when tempo (format t "~4ttempo: ~a~%" tempo))
	(when title (format t "~4ttitle: ~a~%" title))
	(when tool (format t "~4ttool: ~a~%" tool))
	(when track (format t "~4ttrack: ~a~%" track))
	(when writer (format t "~4twriter: ~a~%" writer))
	(when year (format t "~4tyear: ~a~%" year))))
