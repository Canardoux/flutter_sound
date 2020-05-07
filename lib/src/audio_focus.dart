/// Used by [AudioPlayer.audioFocus]
/// to control the focus mode.
enum AudioFocus {
  /// request focus and allow other audio
  /// to continue playing at their current volume.
  focusAndKeepOthers,

  /// request focus and stop other audio playing
  focusAndStopOthers,

  /// request focus and reduce the volume of other players
  /// In the Android world this is know as 'Duck Others'.
  focusAndHushOthers,

  /// relinquish the audio focus.
  abandonFocus,
}
