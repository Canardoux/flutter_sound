import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'flutter_sound.dart';

void main() {
  var recordingPath = Track.tempFile(Codec.aacADTS);
  runApp(_TestDriverApp._internal(recordingPath));
}

class _TestDriverApp extends StatelessWidget {
  final Track _track;

  //
  _TestDriverApp._internal(String recordingPath)
      : _track = Track.fromPath(recordingPath, codec: Codec.aacADTS);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Welcome to Flutter'),
        ),
        body: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    return RecorderPlaybackController(
        child: Column(
      children: [
        SoundRecorderUI(
          _track,
          informUser: informUser,
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: SoundPlayerUI.fromTrack(_track),
        )
      ],
    ));
  }

  Future<bool> informUser(BuildContext context, bool requestingMicrophone,
      bool requestingStorage) async {
    assert(requestingStorage != null);
    assert(requestingMicrophone != null);
    var reason = "To record a message we need permission ";

    var both = false;

    if (requestingMicrophone && requestingStorage) {
      both = true;
    }

    if (requestingMicrophone) {
      reason += "to access your microphone";
    }

    if (both) {
      reason += " and ";
    }

    if (!requestingStorage) {
      reason += "to store a file on your phone";
    }

    if (requestingStorage || requestingMicrophone) {
      reason += ".";

      if (both) {
        reason += " \n\nWhen prompted click the 'Allow' button on "
            "each of the following prompts.";
      } else {
        reason += " \n\nWhen prompted click the 'Allow' button.";
      }

      return showAlertDialog(context, reason);
    }
    return true;
  }

  ///
  Future<bool> showAlertDialog(BuildContext context, String prompt) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () => Navigator.of(context).pop(false),
    );
    Widget continueButton = FlatButton(
      child: Text("Continue"),
      onPressed: () => Navigator.of(context).pop(true),
    );

    // set up the AlertDialog
    var alert = AlertDialog(
      title: Text("Recording Permissions"),
      content: Text(prompt),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return alert;
      },
    );
  }
}
