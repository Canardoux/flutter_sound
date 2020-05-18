## Actually, the following codecs are supported by flutter_sound:

|                 | AAC ADS | Opus OGG | Opus CAF | MP3 | Vorbis OGG | PCM raw| PCM WAV | PCM AIFF | PCM CAF | FLAC | AAC MP4 | AMR-NB | AMR-WB |
| :-------------- | :-----: | :------: | :------: | :-- | :--------- | :--    | :-----: | :------: | :-----: | :--: | :-----: | :----: | :----: |
| iOS encoder     | Yes     |   Yes(*) | Yes      | No  | No         | No     | Yes     | No       | Yes     | Yes  | Yes     | NO     | NO     |
| iOS decoder     | Yes     |   Yes(*) | Yes      | Yes | No         | No     | Yes     | Yes      | Yes     | Yes  | Yes     | NO     | NO     |
| Android encoder | Yes     |   No     | No       | No  | No         | Yes    | Yes     | No       | No      | No   | No      | YES    | YES    |
| Android decoder | Yes     |   Yes    | Yes(*)   | Yes | Yes        | Yes    | Yes     | Yes(*)   | Yes(*)  | Yes  | Yes     | YES    | YES    |

This table will eventually be upgrated when more codecs will be added.

Yes(*) : The codec is supported by Flutter Sound, but with a File Format Conversion. This has several drawbacks :
- Needs FFmpeg. FFmpeg is not included in the LITE flavor of Flutter Sound
- Can add some delay before Playing Back the file, or after stopping the recording. This delay can be substancial for very large records.

-------------------------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#flutter-sound)