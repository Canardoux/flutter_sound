import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../flutter_sound.dart';
import '../codec.dart';
import '../util/format.dart';
import 'grayed_out.dart';
import 'local_context.dart';

// import 'audio_controller.dart';
// import 'audio_media.dart';
// import 'local_context.dart';

/// Describes the state of the playbar.
enum PlayState {
  /// stopped
  stopped,

  ///
  playing,

  ///
  paused,

  ///
  disabled
}

typedef TonLoad = Future<SoundPlayer> Function();

/// A HTML 5 style audio play bar.
/// Allows you to pause/resume and seek and audio track.
class PlayBar extends StatefulWidget {
  /// only codec support by android unless we have a minSdk of 29
  /// then OGG_VORBIS and OPUS are supported.
  static const Codec standardCodec = Codec.codecAac;
  static const int _barHeight = 60;

  /// provides a Duration of 0 seconds.
  static const zero = Duration(seconds: 0);

  final TonLoad _onLoad;
  final SoundPlayer _player;

  /// [PlayBar.fromLoader] allows you to dynamically provide
  /// a [SoundPlayer] when the user clicks the play
  /// button.
  /// You can cancel the play action by returning
  /// null when _onLoad is called.
  PlayBar.fromLoader(TonLoad onLoad)
      : _onLoad = onLoad,
        _player = null;

  /// Constructs a Playbar with a SoundPlayer
  PlayBar.fromPlayer(SoundPlayer player)
      : _player = player,
        _onLoad = null;

  @override
  State<StatefulWidget> createState() {
    return _PlayBarState(_player, _onLoad);
  }
}

class _PlayBarState extends State<PlayBar> {
  SliderPosition sliderPosition = SliderPosition();

  /// we keep our own local stream as the players come and go.
  /// This lets our StreamBuilder work with it worrying about
  /// the player's stream changing under it.
  final _localController = StreamController<PlaybackDisposition>();

  // we are current play (but may be paused)
  PlayState _playState = PlayState.stopped;

  // Indicates that we have start a transition (play to pause etc)
  // and we should block user interaction until the transition completes.
  bool __transitioning = false;

  /// indicates that we have started the player but we are waiting
  /// for it to load the audio resource.
  bool __loading = false;

  /// the active [SoundPlayer].
  /// If the fromLoader ctor is used this will be null
  /// until the user clicks the Play button and onLoad
  /// returns a non null [SoundPlayer]
  SoundPlayer _soundPlayer;

  TonLoad _onLoad;

  StreamSubscription _playerSubscription;

  UniqueKey sliderKey = UniqueKey();

  Slider slider;

  _PlayBarState(this._soundPlayer, this._onLoad) {
    _PlayBarState._internal();
  }

  _PlayBarState._internal() {
    sliderPosition.position = Duration(seconds: 0);
    sliderPosition._maxPosition = Duration(seconds: 0);

    _setCallbacks();
  }

  void _setCallbacks() {
    /// TODO
    /// should we chain these events incase the user of our api
    /// also wants to see these events?
    if (_soundPlayer != null) {
      _soundPlayer.onStarted = ({wasUser}) => _loading = false;
      _soundPlayer.onStopped = ({wasUser}) => playState = PlayState.stopped;
      _soundPlayer.onFinished = () => onFinished();

      /// pipe the new sound players stream to our local controller.
      _soundPlayer.dispositionStream().listen(_localController.add);
    }
  }

  void onFinished() {
    setState(() => playState = PlayState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    // AudioController.of(context).registerPlayer(this);
    return ChangeNotifierProvider<SliderPosition>(
        create: (_) => sliderPosition, child: _buildPlayBar());
  }

  /// Returns the players current state.
  PlayState get playState {
    return _playState;
  }

  set playState(PlayState state) {
    setState(() => _playState = state);
  }

  @override
  void dispose() {
    Log.d("stopping Player on dispose");

    _stop(supressState: true);

    _soundPlayer.release();

    super.dispose();
  }

  Widget _buildPlayBar() {
    return Container(
        decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(PlayBar._barHeight / 2)),
        child: Row(children: [
          _buildPlayButton(),
          Text('${sliderPosition.position.inSeconds}'
              ' / '
              '${Format.duration(sliderPosition._maxPosition)}'),
          Expanded(child: _buildSlider())
        ]));
  }

  Widget _buildSlider() {
    return PlaybarSlider(_localController.stream, _onSeek);
  }

  /// User has clicked the play/pause button.
  void onPlay(BuildContext localContext) {
    switch (playState) {
      case PlayState.stopped:
        start();
        break;

      case PlayState.playing:
        // pause the player
        pause();
        break;
      case PlayState.paused:
        // resume the player
        resume();

        break;
      case PlayState.disabled:
        // shouldn't be possible as play button is disabled.
        _stop();
        break;
    }
  }

  /// Resume the playing.
  void resume() {
    setState(() {
      _transitioning = true;
      playState = PlayState.playing;
    });

    _soundPlayer
        .resume()
        .then((_) => _transitioning = false)
        .catchError((dynamic e) {
      Log.w("Error calling startPlayer ${e.toString()}");

      return null;
    }).whenComplete(() => _transitioning = false);
  }

  /// pause playback.
  void pause() {
    // pause the player
    setState(() {
      _transitioning = true;
      playState = PlayState.paused;
    });

    _soundPlayer
        .pause()
        .then((_) => _transitioning = false)
        .catchError((dynamic e) {
      Log.w("Error calling startPlayer ${e.toString()}");
      playState = PlayState.playing;
      return null;
    }).whenComplete(() => _transitioning = false);
    ;
  }

  /// start playback.
  void start() async {
    setState(() {
      _transitioning = true;
      _loading = true;
      Log.d("Loading starting");
    });

    Log.d("Calling startPlayer");

    if (_soundPlayer != null && _soundPlayer.isPlaying) {
      Log.d("startPlay called whilst player running. Stopping Player first.");
      await _stop();
    }

    if (_onLoad != null) {
      /// dynamically load the player.
      _soundPlayer = await _onLoad();
      _setCallbacks();
    }

    /// no player than just silently ignore the start action.
    /// This means that _onLoad returned null and the user
    /// can display appropriate errors.
    if (_soundPlayer != null) {
      await _start();
    } else {
      setState(() {
        _transitioning = false;
        _loading = false;
        Log.w("No Player provided by _onLoad. Call to start has been ignored");
      });
    }
  }

  void _start() async {

    _soundPlayer.seekTo(sliderPosition.position);
    _soundPlayer.start().then((_) {
      playState = PlayState.playing;
      Log.d("StartPlayer returned");
    }).catchError((dynamic e) {
      Log.w("Error calling startPlayer ${e.toString()}");
      playState = PlayState.stopped;
      return null;
    }).whenComplete(() {
      _loading = false;
      _transitioning = false;
    });
  }

  /// stop playback
  ///
  Future<void> stop() async {
    await _stop();
  }

  Future<void> _stop({bool supressState = false}) async {
    if (_soundPlayer.isPlaying) {
      _soundPlayer.stop().then<void>((_) {
        if (_playerSubscription != null) {
          _playerSubscription.cancel;
          _playerSubscription = null;
        }
      });
    }

    // if called via dispose we can't trigger setState.
    if (supressState) {
      _playState = PlayState.stopped;
      __transitioning = false;
      __loading = false;
    } else {
      playState = PlayState.stopped;
      _transitioning = false;
      _loading = false;
    }

    sliderPosition.position = Duration.zero;
  }

  set _loading(bool value) {
    setState(() => __loading = value);
  }

  bool get _loading {
    return __loading;
  }

  // ignore: avoid_setters_without_getters
  set _transitioning(bool value) {
    setState(() => __transitioning = value);
  }

  void _onSeek(Duration position) {
    sliderPosition.position = position;
    widget._player.seekTo(position);
  }

  Widget _buildPlayButton() {
    Widget button;

    // Log.d("buildPlayButton loading: ${loading} state: ${playState}");
    if (_loading == true) {
      button = Container(
        margin: const EdgeInsets.only(top: 5.0, bottom: 5),
        child:
            SpinKitRing(color: Colors.purple, size: PlayBar._barHeight * 0.6),
      );
      Log.d("#################SpinKit rendered###################");
      // widget = LoadingIndicator(
      //   size: PlayBar.BAR_HEIGHT /2,
      //   color: Theme.of(context).colorScheme.primary);
    } else {
      button = _buildPlayButtonIcon(button);
    }

    return Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: LocalContext(builder: (localContext) {
          return InkWell(
              onTap: ((sliderPosition._maxPosition.inMicroseconds == 0 &&
                          _onLoad == null) ||
                      __transitioning)
                  ? null
                  : () => onPlay(localContext),
              child: button);
        }));
  }

  Widget _buildPlayButtonIcon(Widget widget) {
    switch (playState) {
      case PlayState.playing:
        widget = Icon(Icons.pause,
            color: (sliderPosition._maxPosition.inMicroseconds == 0
                ? Colors.blueGrey
                : Colors.black));
        break;
      case PlayState.stopped:
      case PlayState.paused:
        widget = Icon(Icons.play_arrow,
            color: (sliderPosition._maxPosition.inMicroseconds == 0 &&
                    _onLoad == null
                ? Colors.blueGrey
                : Colors.black));
        break;
      case PlayState.disabled:
        GrayedOut(
            grayedOut: true,
            child: widget = Icon(Icons.play_arrow, color: Colors.blueGrey));
        break;
    }
    return widget;
  }

  void playbackEnabled({bool enabled}) {
    if (enabled == true) {
      playState = PlayState.stopped;
    } else if (enabled == false) {
      _stop();
      playState = PlayState.disabled;
    }
  }

  void updateDuration(Duration duration) {
    setState(() => sliderPosition._maxPosition = duration);
  }
}

///
class PlaybarSlider extends StatefulWidget {
  final void Function(Duration position) _seek;

  ///
  final Stream<PlaybackDisposition> stream;

  ///
  PlaybarSlider(this.stream, this._seek);

  @override
  State<StatefulWidget> createState() {
    return PlaybarSliderState();
  }
}

///
class PlaybarSliderState extends State<PlaybarSlider> {
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
        data: SliderTheme.of(context).copyWith(
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
            inactiveTrackColor: Colors.blueGrey),
        child: StreamBuilder<PlaybackDisposition>(
            stream: widget.stream,
            initialData: PlaybackDisposition.zero(),
            builder: (context, snapshot) {
              var disposition = snapshot.data;
              return Slider(
                value: disposition.position.inSeconds.toDouble(),
                onChanged: (value) =>
                    widget._seek(Duration(seconds: value.toInt())),
                max: disposition.duration.inSeconds.toDouble(),
              );
            }));
  }
}

///
class SliderPosition extends ChangeNotifier {
  Duration _position = Duration.zero;
  Duration _maxPosition = Duration.zero;
  bool _disposed = false;

  ///
  set position(Duration position) {
    _position = position;

    if (!_disposed) notifyListeners();
  }

  void dispose() {
    _disposed = true;
    super.dispose();
  }

  ///
  Duration get position {
    return _position;
  }
}

///
class Log {
  ///
  static void d(String message) => print(message);

  ///
  static void w(String message) => print(message);

  ///
  static void e(String message) => print(message);
}
