## Informations on a record

There are two utilities functions that you can use to have informations on a file.

- FlutterSoundHelper.FFmpegGetMediaInformation(_<A_file_path>_);
- FlutterSoundHelper.duration(_<A_file_path>_)

The informations got with FFmpegGetMediaInformation() are [documented here](https://pub.dev/packages/flutter_ffmpeg).
The integer returned by flutterSound.duration() is an estimation of the number of milli-seconds for the given record.

```
int duration = await flutterSoundHelper.duration( this._path[_codec.index] );
Map<dynamic, dynamic> info = await flutterSoundHelper.FFmpegGetMediaInformation( uri );
```

#