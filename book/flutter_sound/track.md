# Create a `Track` object

In order to play a sound when you initialized the player with the audio player features, you must create a `Track` object to pass to [startPlayerFromTrack]().

The `Track` class is provided by the flutter_sound package. Its constructor takes in 1 required argument and 3 optional arguments:

- `trackPath` (required): a `String` representing the path that points to the audio file to play. This must be provided if `dataBuffer` is null, but you cannot provide both;
- `dataBuffer` (required): a `Uint8List`, a buffer that contains an audio file. This must be provided if `trackPath` is null, but you cannot provide both;
- `trackTitle`: the `String` to display in the notification as the title of the track;
- `trackAuthor` the `String` to display in the notification as the name of the author of the track;
- `albumArtUrl` a `String` representing the URL that points to the image to display in the notification as album art.
- `albumArtFile`  a `String` representing a local file that points to the image to display in the notification as album art.
- `albumArtAsset` : a `String` representing the name of an asset to show in the nofitication

```dart
// Create with the path to the audio file
Track track = new Track(
        trackPath: "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3", // An example audio file
        trackTitle: "Track Title",
        trackAuthor: "Track Author",
        albumArtUrl: "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_1MB.png", // An example image
);

// Load a local audio file and get it as a buffer
Uint8List buffer = (await rootBundle.load('samples/audio.mp3'))
        .buffer
        .asUint8List();
// Create with the buffer
Track track = new Track(
        dataBuffer: buffer,
        trackTitle: "Track Title",
        trackAuthor: "Track Author",
        albumArtUrl: "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_1MB.png", // An example image
);
```

You can specify just one field for the Album Art to display on the lock screen. Either :
- albumArtUrl
- albumArtFile
- albumArtFile

If no Album Art field is specified, Flutter Sound will try to display the App icon.
