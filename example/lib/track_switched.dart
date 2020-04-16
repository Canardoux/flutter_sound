import 'package:flutter/material.dart';

import 'grayed_out.dart';
import 'player_state.dart';

/// UI widget from the TrackPlayer specific settings
/// Allow Tracks and Hush Others
class TrackSwitch extends StatefulWidget {
  final void Function(bool allowTracks) _switchPlayer;

  /// ctor
  const TrackSwitch({
    Key key,
    @required bool isAudioPlayer,
    @required void Function(bool allowTracks) switchPlayer,
  })  : _isAudioPlayer = isAudioPlayer,
        _switchPlayer = switchPlayer,
        super(key: key);

  final bool _isAudioPlayer;

  @override
  _TrackSwitchState createState() => _TrackSwitchState();
}

class _TrackSwitchState extends State<TrackSwitch> {
  _TrackSwitchState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('Allow Tracks:'),
          ),
          GrayedOut(
              grayedOut: !PlayerState().isStopped,
              child: Switch(
                value: widget._isAudioPlayer,
                onChanged: (allow) =>
                    onAudioPlayerSwitchChanged(allowTracks: allow),
              )),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text('Hush Others:'),
          ),
          Switch(
            value: PlayerState().hushOthers,
            onChanged: (hushOthers) =>
                hushOthersSwitchChanged(hushOthers: hushOthers),
          ),
        ],
      ),
    );
  }

  void onAudioPlayerSwitchChanged({bool allowTracks = false}) async {
    widget._switchPlayer(allowTracks);
  }

  void hushOthersSwitchChanged({bool hushOthers}) {
    PlayerState().setHush(hushOthers: hushOthers);
  }
}
