
## TrackPlayer

TrackPlayer is a new flutter_sound module which is able to show controls on the lock screen.
Using TrackPlayer is very simple : just use the TrackPlayer constructor instead of the regular FlutterSoundPlayer.

```dart
trackPlayer = TrackPlayer();
```

You call `startPlayerFromTrack` to play a sound. This function takes in 1 required argument and 4 optional arguments:

- a `Track`, which is the track that the player is going to play;
- `whenFinished:()` : A call back function for specifying what to do when the song is finished
- `onPaused: (boolean)` : A call back function for specifying what to do when the user press the `pause/resume` button on the lock screen.
- `onSkipBackward:()`, A call back function for specifying what to do when the user press the skip-backward button on the lock screen
- `onSkipForward:()`, A call back function for specifying what to do when the user press the skip-forward button on the lock screen

If `onSkipBackward:()` is not specified then the button is not shown on the lock screen.
If `onSkipForward:()` is not specified, then the  button is not shown on the lock screen.
If `onPaused: (boolean)` is not specified, then flutter_sound will handle itself the pause/resume function.
There is actually no way to hide the pause button on the lock screen.

If `onPaused: (boolean)` is specified, then flutter_sound will not handle itself the pause/resume function and it will be the App responsability to handle correctly this function. The boolean argument is `true` if the playback is playing (and probably must me paused). The boolean argument is `false` if the playback is in 'pause' state (and probably must be resumed).

```dart
path = await trackPlayer.startPlayerFromTrack
(
        track,
        whenFinished: ( )
        {
                print( 'I hope you enjoyed listening to this song' );
        },

        onSkipBackward: ( )
        {
                print( 'Skip backward' );
                stopPlayer( );
                startPlayer( );
        },
        onSkipForward: ( )
        {
                print( 'Skip forward' );
                stopPlayer( );
                startPlayer( );
        },
        onPaused: ( boolean mustBePaused)
        {
                if( mustBePaused )
                        trackPlayer.pause();
                else
                        trackPlayer.resume();
        },


);

```

#### Create a `Track` object

In order to play a sound when you initialized the player with the audio player features, you must create a `Track` object to pass to `startPlayerFromTrack`.

The `Track` class is provided by the flutter_sound package. Its constructor takes in 1 required argument and 3 optional arguments:

- `trackPath` (required): a `String` representing the path that points to the audio file to play. This must be provided if `dataBuffer` is null, but you cannot provide both;
- `dataBuffer` (required): a `Uint8List`, a buffer that contains an audio file. This must be provided if `trackPath` is null, but you cannot provide both;
- `trackTitle`: the `String` to display in the notification as the title of the track;
- `trackAuthor` the `String` to display in the notification as the name of the author of the track;
- `albumArtUrl` a `String` representing the URL that points to the image to display in the notification as album art.
- `albumArtFile`  a `String` representing a local file that points to the image to display in the notification as album art.
- or `albumArtAsset` : the name of an asset to show in the nofitication

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
