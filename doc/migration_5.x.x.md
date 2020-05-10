[Back to the README](../README.md#migration-guides)

-----------------------------------------------------------------------------------------------------------------------

# Migration form 4.x.x to 5.x.x

Several changes are necessary to migrate from 4.x.x :

## Imports

To be compliant with Google recommandations, Flutter Sound has now a main dart file that the App must import : `flutter_sound.dart`.
This file is just a list of "exports" from the various dart files present in the "src" sub-directory.


## Global enums and Function types

Global enums are renamed to be compliant with the Google CamelCase recommandations :

- `t_CODECS` is renamed `Codec`.
The `Codec` values are LowerCase, followed by the File Format in Uppercase when there is ambiguity :
   - aacADTS
   - opusOGG
   - opusCAF
   - mp3
   - vorbisOGG
   - pcm16
   - pcm16WAV
   - pcm16AIFF
   - pcm16CAF
   - flac
   - aacMP4

- The Player State is renamed `PlayerState`
- The Recorder State is renamed `RecorderState`
- The iOS Session Category is renamed `SessionCategory`
- The iOS Session Mode is rename `SessionMode`
- The Android Focus Gain is renamed `AndroidFocusGain`

## Flutter Sound does not manage any more the recording permissions.

Now this is the App responsability to request the Recording permission if needed. This change was necessary for several reasons :

- Several App want to manage themselves the permission
- We had some problems with the Flutter Android Embedded V2
- We had problems when Flutter Sound uses permission_handler 4.x and the App needs permission_handler 5.x
- We had problems when Flutter Sound uses permission_handler 5.x and the App needs permission_handler 4.x
- This is not Flutter Sound role to do UI interface

The parameter `requestPermission` is removed from the `startRecorder()` parameters.
The permission_handler dependency is removed from Flutter Sound pubspec.yaml


## The StartRecorder() **"path"** parameter is now mandatory

Flutter Sound does not create anymore files without the App specifying its path.
This was a legacy parameter. The first versions of Flutter Sound created files on the SD-card volume.
This was really bad for many reasons and later versions of Flutter Sound stored its files in a temporary directory.

Flutter Sound Version 5.x.x does not try any more to store files in a temporary directory by itself. Thanks to that, Flutter Sound does not have any more a dependency to `path_provider`. It is now the App responsability to depend on `path_provider` if it wants to access the Temporary Storage.

## StartRecorder() OS specific parameters are removed

We removed OS specific parameters passed during `startRecorder()` :

- AndroidEncoder
- AndroidAudioSource
- AndroidOutputFormat
- IosQuality

## Flutter Sound does not post `NULL` to Player and Recorder subscriptions.

This `NULL` parameter sent when the Recorder or the Player was closed was ugly, and caused many bugs to some Apps.

##  The Audio Focus is not automaticaly abandoned between two startPlayer() or two startRecorder()

The Audio Focus is just abandoned automaticaly when the App does a ```release()```

## Some verbs are renamed :

- The ancient verb `setActive` is now replaced by `setAudioFocus`
- `initialized()` and `release()` are rename `openAudioSession()` and `closeAudioSession()`)

## openAudioSessionWithUI

`openAudioSessionWithUI` is a new verb to open an Audio Session if the App wants to be controlled from the lock-screen. This replace the module `TrackPlayer` which does not exists anymore.

-----------------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#migration-guides)
