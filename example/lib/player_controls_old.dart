import 'package:flutter/material.dart';
import 'package:flutter_sound/flauto.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'active_codec.dart';
import 'grayed_out.dart';
import 'media_path.dart';
import 'player_state.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        buildPlayButton(),
        buildPauseButton(),
        buildStopButton(),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }

  Container buildStopButton() {
    return Container(
      width: 56.0,
      height: 56.0,
      child: ClipOval(
        child: GrayedOut(
            grayedOut: isPlaying(),
            child: FlatButton(
              onPressed: () => PlayerState().stopPlayer(),
              padding: EdgeInsets.all(8.0),
              child: Image(
                width: 28.0,
                height: 28.0,
                image: AssetImage(isPlaying()
                    ? 'res/icons/ic_stop.png'
                    : 'res/icons/ic_stop_disabled.png'),
              ),
            )),
      ),
    );
  }

  Container buildPauseButton() {
    return Container(
      width: 56.0,
      height: 56.0,
      child: ClipOval(
        child: GrayedOut(
            grayedOut: isPlayingOrPaused(),
            child: FlatButton(
              onPressed: () => PlayerState().pauseResumePlayer(),
              padding: EdgeInsets.all(8.0),
              child: Image(
                width: 36.0,
                height: 36.0,
                image: AssetImage(isPaused() != null
                    ? 'res/icons/ic_pause.png'
                    : 'res/icons/ic_pause_disabled.png'),
              ),
            )),
      ),
    );
  }

  Container buildPlayButton() {
    return Container(
      width: 56.0,
      height: 56.0,
      child: ClipOval(
        child: GrayedOut(
            grayedOut: !canStart(),
            child: FlatButton(
              onPressed: () => PlayerState().startPlayer(),
              padding: EdgeInsets.all(8.0),
              child: Image(
                image: AssetImage(canStart()
                    ? 'res/icons/ic_play.png'
                    : 'res/icons/ic_play_disabled.png'),
              ),
            )),
      ),
    );
  }

  bool canStart() {
    if (MediaPath().isFile ||
        MediaPath().isBuffer) // A file must be already recorded to play it
    {
      if (!MediaPath().exists(ActiveCodec().codec)) return false;
    }
    if (MediaPath().isExampleFile && ActiveCodec().codec != t_CODEC.CODEC_MP3) {
      return false;
    }

    // Disable the button if the selected codec is not supported
    if (!ActiveCodec().decoderSupported) return false;

    if (!isStopped()) return false;

    return true;
  }

  bool isStopped() => (audioState == t_AUDIO_STATE.IS_STOPPED);

  t_AUDIO_STATE get audioState {
      if (PlayerState().isPlaying) return t_AUDIO_STATE.IS_PLAYING;
      if (PlayerState().isPaused) return t_AUDIO_STATE.IS_PAUSED;

    return t_AUDIO_STATE.IS_STOPPED;
  }

  bool isPlaying() {
    return audioState == t_AUDIO_STATE.IS_PLAYING;
  }

  bool isPlayingOrPaused() {
    return isPlaying() || audioState == t_AUDIO_STATE.IS_PAUSED;
  }

  bool isPaused() {
    return audioState == t_AUDIO_STATE.IS_PAUSED;
  }
}
