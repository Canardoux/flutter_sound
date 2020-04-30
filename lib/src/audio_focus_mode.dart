/// Used by [AudioPlayer.audioFocus]
/// to control the focus mode.
enum AudioFocusMode {
  /// request focus and allow other audio
  /// to continue playing at their current volume.
  focusAndKeepOthers,

  /// request focus and stop other audio playing
  focusAndStopOthers,

  /// request focus and reduce the volumen of other players
  focusAndDuckOthers,

  /// relinquish the audio focus.
  abandonFocus,
}
