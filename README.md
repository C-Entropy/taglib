Copyright (c) 2013, Mark VandenBrink. All rights reserved.

# Introduction

A pure Lisp implementation for reading MPEG-4 audio and MPEG-3 audio tags and audio information.

**Mostly complete.  Your mileage may vary. Most definitely, NOT portable.  Heavily dependent on Clozure CCL.**

# Dependencies

All avalailable via quicklisp

* log5
* alexandria
* cl-fad

# References

Note: There a lot of good (some great) audio file resources out there.  Here are a few of them that I found useful:

* [l-smash](http://code.google.com/p/l-smash/): Exhaustively comprehensive MP4 box parser in C.
* [taglib](http://taglib.github.io/): Clean library in C++.
* [mplayer](http://www.mplayerhq.hu): For me, the definitive tool on how to crack audio files.
* [eyeD3](http://eyed3.nicfit.net/): Great command line tool.
* [MP3Diags](http://mp3diags.sourceforge.net/): Good GUI-based-tool.  Tends to slow, but very thorough.
* [MediaInfo](http://mediaarea.net/en/MediaInfo): C++, can dump out all the info to command line and also has a GUI.
* [The MP4 Book](http://www.amazon.com/gp/search?index=books&linkCode=qs&keywords=0130616214): I actually didn't order this until well into writing this code.   What a maroon. 
  It would have saved me TONS of time.

# General Notes

* As the author(s) of taglib state in their comments, parsing ID3s is actually pretty hard. There are so many broken taggers out there
  that it is tough to compensate for all their errors.
* The parsing of MP3 audio properties (mpeg.lisp) is far from complete, especially when dealing with odd case WRT Xing headers.
* I've parsed just enough of the MP4 atoms/boxes to suit the needs of this tool.  l-smash appears to parse all boxes.  Maybe one day this lib will too.
* WRT error handling: in some cases, I've made them recoverable, but in general, I've went down the path of erroring out when
  I get problems. 
* I've run this tool across my 21,000+ audio collection and compared the results to some of the tools above, with little to no variations.
  That said, I have a pretty uniform collection, mostly from ripping CDs, then iTunes purchases/matched, and the Amazon matched. YMMV
* Parsing the CBR audio info in an MP3 is hideously inefficient if done exhaustively.  Instead, this library, only looks at the first
  MPEG frame and calculates the duration, etc from that.  In addition, if you just want TAG info, you can bind AUDIO-STREAMS:*get-audio-info* to nil.
* The library is reasonably fast: on a USB 2.0 disk, once the filesystem cache is "hot", it parses my ~21,000 files in about
  24 seconds (while getting audio-info)

Things to consider adding/changing:

* Add more file types.
* Add writing of tags.
* Improve error handling.
* Implement a DSL ala Practical Common Lisp.

# Sample Invocations and Results

````
(let (foo)
    (unwind-protect
        (setf foo (parse-mp4-file "01 Keep Yourself Alive.m4a"))
    (when foo 
	    (mp4-tag:show-tags foo)
		(stream-close foo)))

````

Yields:

```
01 Keep Yourself Alive.m4a
sample rate: 44100.0 Hz, # channels: 2, bits-per-sample: 16, max bit-rate: 314 Kbps, avg bit-rate: 256 Kbps, duration: 4:03
    album: Queen I
    album-artist: Queen
    artist: Queen
    compilation: no
    disk: (1 1)
    genre: 80 (Hard Rock)
    title: Keep Yourself Alive
    track: (1 11)
    year: 1973
```

The show-tags methods also have a "raw" capability.  Example:

```
(let (foo)
    (unwind-protect
        (setf foo (parse-mp3-file "Queen/At the BBC/06 Great King Rat.mp3"))
    (when foo
		  (mp3-tag:show-tags foo :raw t)
		   (stream-close foo)))

```

Yields:

```
Queen/At the BBC/06 Great King Rat.mp3: MPEG 1, Layer III, VBR, sample rate: 44,100 Hz, bit rate: 128 Kbps, duration: 5:60
Header: version/revision: 3/0, flags: 0x00: 0/0/0/0, size = 11,899 bytes; No extended header; No V21 tag
    Frames[9]:
        frame-text-info: flags: 0x0000: 0/0/0/0/0/0, offset: 0, version = 3, id: TIT2, len: 15, NIL, encoding = 0, info = <Great King Rat>
        frame-text-info: flags: 0x0000: 0/0/0/0/0/0, offset: 25, version = 3, id: TPE1, len: 6, NIL, encoding = 0, info = <Queen>
        frame-text-info: flags: 0x0000: 0/0/0/0/0/0, offset: 41, version = 3, id: TPE2, len: 6, NIL, encoding = 0, info = <Queen>
        frame-text-info: flags: 0x0000: 0/0/0/0/0/0, offset: 57, version = 3, id: TALB, len: 11, NIL, encoding = 0, info = <At the BBC>
        frame-text-info: flags: 0x0000: 0/0/0/0/0/0, offset: 78, version = 3, id: TRCK, len: 4, NIL, encoding = 0, info = <6/8>
        frame-text-info: flags: 0x0000: 0/0/0/0/0/0, offset: 92, version = 3, id: TPOS, len: 4, NIL, encoding = 0, info = <1/1>
        frame-text-info: flags: 0x0000: 0/0/0/0/0/0, offset: 106, version = 3, id: TYER, len: 5, NIL, encoding = 0, info = <1995>
        frame-text-info: flags: 0x0000: 0/0/0/0/0/0, offset: 121, version = 3, id: TCON, len: 5, NIL, encoding = 0, info = <(79)>
        frame-txxx: flags: 0x0000: 0/0/0/0/0/0, offset: 136, version = 3, id: TXXX, len: 33, NIL, <Tagging time/2013-08-08T16:38:38>
```

## Logging

I have a semi-complete logging strategy in place that is primarily used to figure out what happened when I get
an unexpected error parsing a file. To see the output of ALL logging statements to *STANDARD-OUTPUT*, you can do the following:

```
(with-logging ()
    (test2::test2))
```

To see only the MP4-ATOM related logging stuff and redirect logging to to a file called "foo.txt":

```
(with-logging ("foo.txt" :categories (categories '(mp4-atom::cat-log-mp4-atom)))
    (taglib-tests::test2))
```

See *logging.lisp* for more info.

If you *really* want to create a lot of output, you can do the following:

```
(with-logging ("log.txt")
    (redirect "q.txt" (test2 :dir "somewhere-where-you-have-all-your-audio" :raw t)))
```

For my 21,000+ files, this generates 218,788,792 lines in "log.txt" and 240,727 lines in "q.txt".

# Design

## The Files

* _audio-streams.lisp:_ creates a STREAM-like interface to audio files and vectors, thus read/seek devolve into
  simple array-references.  For files, it uses CCL's MAP-FILE-TO-OCTET-VECTOR function to mmap the file.
* _id3-frame.lisp:_ Parses the ID3 frames in an MP3 file.
   For each frame type we are interested in, DEFCLASS a class with
   specfic naming convention: frame-xxx/frame-xxxx, where xxx is valid ID3V2.2 frame name
   and xxxx is a valid ID3V2.[34] frame name.  Upon finding a frame name in an MP3 file,
   we can then do a FIND-CLASS on the "frame-xxx", and a MAKE-INSTANCE on the found class
   to read in that class (each defined class is assumed to have an INITIALIZE-INSTANCE method
   that reads in data to build class.
	* _iso-639-2.lisp:_ Converts ISO-639-2 3-character languages into longer, more descriptive strings.
	* _logging.lisp:_ Defines a logging system based on LOG5. Used to debug flow.  See above for how to use.
	* _mp3-tag.lisp:_ The abstract interface for ID3 tags for MP3s. The abstract interface is simply one of the following:
	* _album:_ Returns the name of the album.
	* _album-artist:_ Returns the name of album artist.
	* _artist:_ Returns recording artist.
	* _comment:_ Returns any comments found in file.
	* _compilation:_ A boolean indicating whether this file is part of a compilation.
	* _composer:_  Returns the composer of this file.
	* _copyright:_ Returns copyright info.
	* _disk:_ Returns the disk number of this file.  If present, may be a single number or two numbers (ie disk 1 of 2).
	* _encoder:_ Returns the tool used to encode this file.
	* _genre:_ Returns the genre of this file.
	* _groups:_ (not entirely sure...)
	* _lyrics:_ Returns any (unsynchronized) lyrics found in this file.
	* _tempo:_ Returns the tempo of this file.
	* _title:_ Returns the name of the the song in this file.
	* _track:_ Returns the track number of this file.  Like *disk*, if present, may be a single number or two numbers (ie track 1 of 20).
	* _writer:_ Returns name of who wrote this song.
	* _year:_ Returns the year when the song was recorded.
  Each frame class assumes that the STREAM being passed has been made sync-safe.

  For any class we don't want to parse (eg, haven't gotten around to it yet, etc), we create
  a RAW-FRAME class that can be subclassed.  RAW-FRAME simply reads in the frame header, and then
  the frame "payload" as raw OCTETS.
* _mp4-atom.lisp:_ Parses MP4 audio files.  Similar logic to _id-frame.lisp_, but has two main differnces: first,
  it returns a tree stucture (needed, since, that's how M4A atoms/boxes work, and secondly, has an *atom-skip* class
  that records the name and position of an atom, but seeks to the next atom rather than reading in contents.

  As noted in the comments of this file, there are three kinds of "boxes/atoms":
    * Pure container atoms: have no data and are only used to contain other atoms.  This is akin to a UNIX filesystem's directory notion.
    * Pure "data" atoms: has no nested atoms.  Only has a payload.
    * A mixture of both.
* _mp4-tag.lisp:_ The abstract interface for MP4 audio files. See mp3-tag.lisp for the abstract interface description.
* _mpeg.lisp:_ Parses the audio information (ie the non-ID3 info) in an MP3 file.
* _packages.lisp:_ Holds all the package definitions.
* _taglib-tests.asd:_ Contains build instructions for taglib-tests.lisp.  An ASDF file.
* _taglib-tests.lisp:_ Some test invocations.
* _taglib.asd:_ Contains build instructions for taglib library.  An ASDF file.
* _utils.lisp:_ General utility functions/methods needed by this library.





