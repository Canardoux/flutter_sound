# Migration from 3.x.x to 4.x.x

There is no changes in the 4.x.x version API.
But some modifications are necessary in your configuration files

The `FULL` flavor of Flutter Sound makes use of flutter_ffmpeg. In contrary to Flutter Sound Version 3.x.x, in Version 4.0.x your App can be built without any Flutter-FFmpeg dependency.

If you come from Flutter Sound Version 3.x.x, you must :

- Remove this dependency from your ```pubspec.yaml```.
- You must also delete the line ```ext.flutterFFmpegPackage = 'audio-lts'``` from your ```android/build.gradle```
- And the special line ```pod name+'/audio-lts', :path => File.join(symlink, 'ios')``` in your Podfile.

If you do not do that, you will have duplicates modules during your App building.

```flutter_ffmpeg audio-lts``` is now embedding inside the `FULL` flavor of Flutter Sound. If your App needs to use FFmpeg, you must use the embedded version inside flutter_sound
instead of adding a new dependency in your pubspec.yaml.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#migration-guides)