import 'dart:async';



/// Used to track the players state.
class PlayerState {
  static final PlayerState _self = PlayerState._internal();

  bool _hushOthers = false;

  /// factory to retrieve a PlayerState
  factory PlayerState() {
    return _self;
  }

  PlayerState._internal();

  /// returns [true] if hushOthers (reduce other players volume)
  /// is enabled.
  bool get hushOthers => _hushOthers;

  /// When we play something during whilst other audio is playing
  ///
  /// E.g. if Spotify is playing
  /// We can:
  // Stop Spotify
  // Play both our sound and Spotify
  // Or lower Spotify Sound during our playback.
  /// [setHush] controls option three.
  /// When passsing [true] to [setHush] the other auidio
  /// player's (e.g. spotify) sound is lowered.
  ///
  Future<void> setHush({bool hushOthers}) async {
    _hushOthers = hushOthers;
  }
}
