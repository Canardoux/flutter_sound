---
title:  "Codecs"
description: "Supported codecs."
summary: "Supported codecs."
permalink: guides_codec.html
tags: [guide]
keywords: guides
---

## Supported Codecs

### On mobile OS

Actually, the following codecs are supported by flutter\_sound:

|  | iOS encoder | iOS decoder | Android encoder | Android decoder |
| :--- | :---: | :---: | :---: | :---: |
| AAC ADTS | ✅ | ✅ | ✅ \(1\) | ✅ |
| Opus OGG | ✅ \(\*\) | ✅ \(\*\) | ❌ | ✅ \(1\) |
| Opus CAF | ✅ | ✅ | ❌ | ✅ \(\*\) \(1\) |
| MP3 | ❌ | ✅ | ❌ | ✅ |
| Vorbis OGG | ❌ | ❌ | ❌ | ✅ |
| PCM16 | ✅ | ✅ | ✅ \(1\) | ✅ |
| PCM Wave | ✅ | ✅ | ✅ \(1\) | ✅ |
| PCM AIFF | ❌ | ✅ | ❌ | ✅ \(\*\) |
| PCM CAF | ✅ | ✅ | ❌ | ✅ \(\*\) |
| FLAC | ✅ | ✅ | ❌ | ✅ |
| AAC MP4 | ✅ | ✅ | ✅ \(1\) | ✅ |
| AMR NB | ❌ | ❌ | ✅ \(1\) | ✅ |
| AMR WB | ❌ | ❌ | ✅ \(1\) | ✅ |
| PCM8 | ❌ | ❌ | ❌ | ❌ |
| PCM F32 | ❌ | ❌ | ❌ | ❌ |
| PCM WEBM | ❌ | ❌ | ❌ | ❌ |
| Opus WEBM | ❌ | ❌ | ✅ | ✅ |
| Vorbis WEBM | ❌ | ❌ | ❌ | ✅ |

This table will eventually be upgraded when more codecs will be added.

* ✅ \(\*\) : The codec is supported by Flutter Sound, but with a File Format Conversion. This has several drawbacks :
  * Needs FFmpeg. FFmpeg is not included in the LITE flavor of Flutter Sound
  * Can add some delay before Playing Back the file, or after stopping the recording. This delay can be substancial for very large records.
* ✅ \(1\) : needs MinSDK &gt;=23

### On Web browsers

|  | Chrome encoder | Chrome decoder | Firefox encoder | Firefox decoder | Webkit encoder \(safari\) | Webkit decoder   \(Safari\) |  |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| AAC ADTS | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |  |
| Opus OGG | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ |  |
| Opus CAF | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |  |
| MP3 | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |  |
| Vorbis OGG | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |  |
| PCM16 | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | \(must be verified\) |
| PCM Wave | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |  |
| PCM AIFF | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM CAF | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |  |
| FLAC | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |  |
| AAC MP4 | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |  |
| AMR NB | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| AMR WB | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM8 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM F32 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM WEBM | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| Opus WEBM | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |  |
| Vorbis WEBM | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |  |

* Webkit is bull shit : you cannot record anything with Safari, or even Firefox/Chrome on iOS.
* Opus WEBM is a great Codec. It works on everything \(mobile and Web Browsers\), except Apple
* Edge is same as Chrome

