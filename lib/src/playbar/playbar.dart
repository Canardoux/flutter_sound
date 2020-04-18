import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../flutter_sound.dart';
import '../codec.dart';
import '../util/format.dart';
import '../util/stop_watch.dart';
import 'grayed_out.dart';
import 'local_context.dart';
import 'playbar_slider.dart';
import 'slider_position.dart';

// import 'audio_controller.dart';
// import 'audio_media.dart';
// import 'local_context.dart';

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
  final bool _showTitle;

  /// [PlayBar.fromLoader] allows you to dynamically provide
  /// a [SoundPlayer] when the user clicks the play
  /// button.
  /// You can cancel the play action by returning
  /// null when _onLoad is called.
  PlayBar.fromLoader(TonLoad onLoad, {bool showTitle = false})
      : _onLoad = onLoad,
        _showTitle = showTitle,
        _player = null;

  /// Constructs a Playbar with a SoundPlayer
  PlayBar.fromPlayer(SoundPlayer player, {bool showTitle = false})
      : _player = player,
        _showTitle = showTitle,
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
  final _localController = StreamController<PlaybackDisposition>.broadcast();

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
    sliderPosition.maxPosition = Duration(seconds: 0);

    _setCallbacks();
  }

  /// detect hot reloads when debugging and stop the player.
  /// If we don't the platform specific code keeps running
  /// and sending methodCalls to a slot that no longe exists.
  @override
  void reassemble() async {
    super.reassemble();
    if (_soundPlayer != null) {
      if (playState != PlayState.stopped) {
        await stop();
      }
      _soundPlayer.release();
      _soundPlayer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // AudioController.of(context).registerPlayer(this);
    return ChangeNotifierProvider<SliderPosition>(
        create: (_) => sliderPosition, child: _buildPlayBar());
  }

  void _setCallbacks() {
    /// TODO
    /// should we chain these events incase the user of our api
    /// also wants to see these events?
    if (_soundPlayer != null) {
      _soundPlayer.onStarted = ({wasUser}) => _loading = false;
      _soundPlayer.onStopped = ({wasUser}) => playState = PlayState.stopped;
      _soundPlayer.onFinished =
          () => setState(() => playState = PlayState.stopped);

      /// pipe the new sound players stream to our local controller.
      _soundPlayer.dispositionStream().listen(_localController.add);
    }
  }

  @override
  void dispose() {
    Log.d("stopping Player on dispose");
    _stop(supressState: true);
    _soundPlayer.release();
    super.dispose();
  }

  Widget _buildPlayBar() {
    var rows = <Widget>[];
    rows.add(
        Row(children: [_buildPlayButton(), _buildDuration(), _buildSlider()]));
    if (widget._showTitle && _soundPlayer != null) rows.add(_buildTitle());

    return Container(
        decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(PlayBar._barHeight / 2)),
        child: Column(children: rows));
  }

  /// Returns the players current state.
  PlayState get playState {
    return _playState;
  }

  set playState(PlayState state) {
    setState(() => _playState = state);
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
      _start();
    } else {
      setState(() {
        _transitioning = false;
        _loading = false;
        Log.w("No Player provided by _onLoad. Call to start has been ignored");
      });
    }
  }

  /// internal start method.
  void _start() async {
    // _soundPlayer.seekTo(sliderPosition.position);
    var watch = StopWatch('start');
    _soundPlayer.start().then((_) {
      playState = PlayState.playing;
      watch.end();
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

  ///
  /// interal stop method.
  ///
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

  /// put the ui into a 'loading' state which
  /// will start the spinner.
  set _loading(bool value) {
    setState(() => __loading = value);
  }

  /// current loading state.
  bool get _loading {
    return __loading;
  }

  /// When we are moving between states we mark
  /// ourselves as 'transition'.
  // ignore: avoid_setters_without_getters
  set _transitioning(bool value) {
    setState(() => __transitioning = value);
  }

  /// Build the play button which includes the loading spinner and pause button
  ///
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
              onTap: ((sliderPosition.maxPosition.inMicroseconds == 0 &&
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
        widget = Icon(Icons.pause, color: Colors.black);
        break;
      case PlayState.stopped:
      case PlayState.paused:
        widget = Icon(Icons.play_arrow,
            color: (sliderPosition.maxPosition.inMicroseconds == 0 &&
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

  Widget _buildDuration() {
    return StreamBuilder<PlaybackDisposition>(
        stream: _localController.stream,
        initialData: PlaybackDisposition.zero(),
        builder: (context, snapshot) {
          var disposition = snapshot.data;
          return Text(
              '${Format.duration(disposition.position, showSuffix: false)}'
              ' / '
              '${Format.duration(disposition.duration)}');
        });
  }

  Widget _buildSlider() {
    return Expanded(
        child: PlaybarSlider(
      _localController.stream,
      (position) {
        sliderPosition.position = position;
        _soundPlayer.seekTo(position);
      },
    ));
  }

  Widget _buildTitle() {
    return Container(
      margin: EdgeInsets.only(left: 45, bottom: 5),
      child: Row(children: [
        Text(_soundPlayer.trackTitle),
        Text(' / '),
        Text(_soundPlayer.trackAuthor)
      ]),
    );
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
