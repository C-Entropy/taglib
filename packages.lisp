;;; -*- Mode: Lisp;  show-trailing-whitespace: t; Base: 10; indent-tabs: nil; Syntax: ANSI-Common-Lisp; Package: CL-USER; -*-
;;; Copyright (c) 2013, Mark VandenBrink. All rights reserved.
(in-package #:cl-user)

(defpackage #:utils
  (:export #:warn-user *break-on-warn-user* #:printable-array #:upto-null #:redirect
           #:it #:fastest #:get-bitfield #:while #:aif #:awhen #:with-gensyms #:make-keyword #:dump-data)
  (:use #:common-lisp))

(defpackage #:iso-639-2
  (:export #:get-iso-639-2-language)
  (:use #:common-lisp :utils))

(defpackage #:audio-streams
  (:export #:octets #:make-octets *get-audio-info* #:audio-stream-condition
           #:mp3-file-stream #:mp4-file-stream #:base-mem-stream #:flac-file-stream #:flac-tags
           #:id3-header #:audio-info #:mp4-atoms #:flac-headers
           #:parse-mp3-file #:parse-mp4-file #:parse-audio-file #:parse-flac-file #:flac-tags
           #:make-mem-stream #:make-file-stream #:stream-filename
           #:stream-read-u8 #:stream-read-u16 #:stream-read-u24 #:stream-read-u32 #:stream-read-u64 #:stream-read-u128 #:stream-read-octets
           #:stream-decode-iso-string #:stream-deocode-ucs-string #:stream-decode-ucs-be-string
           #:stream-decode-utf-8-string #:stream-decode-string #:stream-read-iso-string-with-len
           #:stream-read-ucs-string-with-len #:stream-read-ucs-be-string-with-len
           #:stream-read-utf-8-string-with-len #:stream-read-string-with-len
           #:stream-read-iso-string #:stream-read-ucs-string #:stream-read-ucs-be-string
           #:stream-read-utf-8-string #:stream-read-string
           #:stream-read-string #:stream-read-sequence #:stream-size
           #:stream-seek #:stream-close)
  (:use #:common-lisp #:utils))

(defpackage #:flac-frame
  (:export #:flac-frame-condition #:flac-header #:vpprint #:is-valid-flac-file #:find-flac-frames
           #:get-flac-audio-info #:flac-get-tag #:get-flac-audio-info #:flac-show-raw-tag)
  (:use #:common-lisp #:utils #:audio-streams))

(defpackage #:mp4-atom
  (:export #:mp4-atom #:map-mp4-atom #:find-mp4-atoms #:traverse #:mp4-atom-condition
           #:atom-file-position #:atom-children #:atom-size #:atom-of-interest #:atom-decoded
           #:atom-type #:vpprint #:*tag-path* #:tag-get-value #:mp4-atom-condition
           #:mp4-show-raw-tag-atoms #:get-mp4-audio-info #:is-valid-m4-file
           #:+itunes-album+
           #:+itunes-album-artist+
           #:+itunes-artist+
           #:+itunes-comment+
           #:+itunes-composer+
           #:+itunes-copyright+
           #:+itunes-year+
           #:+itunes-encoder+
           #:+itunes-groups+
           #:+itunes-lyrics+
           #:+itunes-purchased-date+
           #:+itunes-title+
           #:+itunes-tool+
           #:+itunes-writer+
           #:+itunes-compilation+
           #:+itunes-cover-art+
           #:+itunes-disk+
           #:+itunes-genre+
           #:+itunes-genre-x+
           #:+itunes-tempo+
           #:+itunes-track+
           #:+itunes-track-n+)
  (:use #:common-lisp #:audio-streams #:utils))

(defpackage #:id3-frame
  (:export #:id3-frame #:find-id3-frames #:id3-frame-condition #:vpprint #:header #:get-frame-info #:is-valid-mp3-file
           #:encoding #:lang #:desc #:val #:comment #:artist #:album #:year #:comment #:year
           #:map-id3-frames #:frames #:year #:title #:genre #:id #:v21-tag-header #:info #:version)
  (:use #:common-lisp #:audio-streams #:utils #:iso-639-2))

;; (defpackage #:mp3-tag
;;   (:export #:show-tags #:get-id3v1-genre)
;;   (:use #:common-lisp #:audio-streams #:id3-frame #:utils))

;; (defpackage #:mp4-tag
;;   (:export #:show-tags #:album #:album-artist #:artist #:comment #:composer #:copyright #:created
;;            #:encoder #:groups #:lyrics #:purd #:title #:tool #:writer)
;;   (:use #:common-lisp #:audio-streams #:utils))

(defpackage #:abstract-tag
  (:export #:show-tags #:get-id3v1-genre
           #:album #:album-artist #:artist #:comment #:composer #:copyright #:created
           #:encoder #:groups #:lyrics #:purd #:title #:tool #:writer)
  (:use #:common-lisp #:audio-streams #:id3-frame #:utils))


(defpackage #:logging
  (:export #:with-logging)
  (:use #:common-lisp #:utils))

(defpackage #:mpeg
  (:export #:get-mpeg-audio-info #:vpprint)
  (:use #:common-lisp #:audio-streams #:utils))
