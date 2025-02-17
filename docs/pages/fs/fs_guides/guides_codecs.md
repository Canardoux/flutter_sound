---
title:  "Codecs"
summary: "Supported codecs."
permalink: fs-guides_codec.html
---

## Supported Codecs

### On mobile OS

Actually, the following codecs are supported by flutter\_sound:

|  | iOS encoder | iOS decoder | Android encoder | Android decoder |
| :--- | :---: | :---: | :---: | :---: |
| AAC ADTS | ✅ | ✅ | ✅ \(1\) | ✅ |
| Opus OGG | ❌ | ❌ | ❌ | ✅ \(1\) |
| Opus CAF | ✅ | ✅ | ❌ | ❌ |
| MP3 | ❌ | ✅ | ❌ | ✅ |
| Vorbis OGG | ❌ | ❌ | ❌ | ✅ |
| PCM16 | ✅ | ✅ | ✅ \(1\) | ✅ |
| PCM Wave | ✅ | ✅ | ✅ \(1\) | ✅ |
| PCM AIFF | ❌ | ✅ | ❌ | ❌ |
| PCM CAF | ✅ | ✅ | ❌ | ❌ |
| FLAC | ✅ | ✅ | ❌ | ✅ |
| AAC MP4 | ✅ | ✅ | ✅ \(1\) | ✅ |
| AMR NB | ❌ | ❌ | ✅ \(1\) | ✅ |
| AMR WB | ❌ | ❌ | ✅ \(1\) | ✅ |
| PCM8 | ❌ | ❌ | ❌ | ❌ |
| PCM F32 | ❌ | ❌ | ❌ | ❌ |
| PCM WEBM | ❌ | ❌ | ❌ | ❌ |
| Opus WEBM | ❌ | ❌ | ❌ | ✅ |
| Vorbis WEBM | ❌ | ❌ | ❌ | ✅ |

This table will eventually be upgraded when more codecs will be added.

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
| AAC MP4 | ❌ | ✅ | ❌ | ✅ | ✅  | ✅ |  |
| AMR NB | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| AMR WB | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM8 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM F32 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM WEBM | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| Opus WEBM | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |  |
| Vorbis WEBM | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |  |

* On Webkit (Safari and all browsers on iOS) we can only record MP4.
* Opus WEBM is a great Codec. It works on everything \(mobile and Web Browsers\), except Apple :-(
* Edge is same as Chrome

