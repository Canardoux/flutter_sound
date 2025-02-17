---
title: "Etau CHANGELOG"
description: The Etau Project CHANGELOG
permalink: etau-CHANGELOG.html
summary: The Changelog of The Etau Project.
---
## 0.0.1 - 2025/02/10

- Flutter Sound does not depend any more on etau/tau_web

## TODO

- On Web : Record/Playback PcmFloat32 not interleaved : NeedSomeFood : DartError: Bad state: Future already completed
- On Web : Implement Stream interleaved.   - Implement stream not interleaved on Android
- On Web : Record PCMFloat32 : DartError: Assertion failed: file:///Volumes/mac-H/larpoux/proj/flutter_sound/flutter_sound_web/lib/
- On Web : PCM16 Dart Stream not OK
- On Web : Implement Streams Int16 
- On web : Streams for codec.pcmFloat32 and not interleaved

- On iOS : Streams Int16 not interleaved - On iOS : Codec.pcmINT16 not interleaved
- Pause/Resume for PCM codecs
- Set Volume for PCM codecs
- Set Pan for PCM codecs
- pcmFloat32 and pcmFloat32WAV on Android - Implement Float32 on Android - On Android : Record/Playback PCMFloat32

- Playback OpusWEBM and VorbisWEBM with remote files on Android
- Volume Control for pcm codecs (all platforms)
- Example Pan control
- On iOS, the peak level is more than 100 db
- On Web : isEncoderSupported() and isDecoderSupported() are not implemented
- On Web : playback OpusOGG does not work
- On Wev : Record/playback AAC/MP4 and OpusWEB to buffer
- flutter_sound_recorder_web.dart:279:14
- https://tau.canardoux.xyz/danku/extract/02-opus.webm Not found
- https://tau.canardoux.xyz/danku/extract/03-vorbis.webm Not found
- Playback Asset PCM Float32 : onloaderror
- On Web : startPlayer FromURI : _flutter_sound.wav : No file extension was found. Consider using the "format" property or specify an extension.
- On iOS : codec==Codec.pcm16WAV  --  startRecorder()  --  The frames are not correctely coded with int16 but float32. This must be fixed.
- MacOS support
- Doc
- Taudio
- DB Peak when Channel Count > 1
- Flutter Sound 10.0-Alpha

## 0.0.0 - 2025/02/10

- FInitial Version
- Flutter Sound does not depend anymore on Audio_Session
