import 'codec.dart';
import 'sound_player.dart';

typedef TrackAction = void Function(Track current);

class Track {
  TrackProxy _proxy;
  SoundPlayer _player;

  TrackAction onSkipForward;
  TrackAction onSkipBackward;
  PlayerEvent onFinished;

  ///
  Track.fromPath(String url, {Codec codec}) {
    Track._internal(url, codec);
  }

  Track._internal(String url, Codec codec) {
    _proxy = TrackProxy.fromPath(url, codec: codec);
    _player = _proxy.player;

    _player.onSkipBackward = _skipBackwards;
    _player.onSkipForward = _skipForward;
  }

  void play() {

    /// TODO we need to be able to late initialise a SoundPlayer
    /// so we can initialise/release tracks as we go.
    _player.initialise();
    _player.play();
  }

  void pause() {
    _player.pause();
  }

  void resume() {
    _player.resume();
  }

  void stop() {
    _player.stop();
  }

  void _skipForward() {
    if (onSkipForward != null) onSkipForward(this);
  }

  void _skipBackwards() {
    if (onSkipBackward != null) onSkipBackward(this);
  }
}
