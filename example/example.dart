import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../lib/flutter_sound.dart';

void main() {
  var recordingPath = Track.tempFile(Codec.aacADTS);
  runApp(SoundExampleApp._internal(recordingPath));
}

class SoundExampleApp extends StatelessWidget {
  final Track _track;

  //
  SoundExampleApp._internal(String recordingPath)
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
    // link the recorder and player so you can record
    // and then playback the message.
    // Note: the recorder and player MUST share the same track.
    return RecorderPlaybackController(
        child: Column(
      children: [
        /// Add the recorder
        SoundRecorderUI(
          /// the track to record into.
          _track,

          /// callback for when recording needs permissions
          requestPermissions: requestPermissions,
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          // add the player
          child: SoundPlayerUI.fromTrack(_track),
        )
      ],
    ));
  }

  /// Callback for when the recorder needs permissions to record
  /// to the [track].
  Future<bool> requestPermissions(BuildContext context, Track track) async {
    bool granted = false;

    /// change this to true if the track doesn't use external storage on android.
    bool usingExternalStorage = false;

    // Request Microphone permission if needed
    print('storage: ${await Permission.microphone.status}');
    var microphoneRequired = !await Permission.microphone.isGranted;

    bool storageRequired = false;

    if (usingExternalStorage) {
      /// only required if track is on external storage
      if (Permission.storage.status == PermissionStatus.undetermined) {
        print(
            'You are probably missing the storage permission in your manifest.');
      }

      storageRequired =
          usingExternalStorage && !await Permission.storage.isGranted;
    }

    /// build the 'reason' why and what we are asking permissions for.
    if (microphoneRequired || storageRequired) {
      var both = false;

      if (microphoneRequired && storageRequired) {
        both = true;
      }

      var reason = "To record a message we need permission ";

      if (microphoneRequired) {
        reason += "to access your microphone";
      }

      if (both) {
        reason += " and ";
      }

      if (storageRequired) {
        reason += "to store a file on your phone";
      }

      reason += ".";

      if (both) {
        reason += " \n\nWhen prompted click the 'Allow' button on "
            "each of the following prompts.";
      } else {
        reason += " \n\nWhen prompted click the 'Allow' button.";
      }

      /// tell the user we are about to ask for permissions.
      if (await showAlertDialog(context, reason)) {
        var permissions = <Permission>[];
        if (microphoneRequired) permissions.add(Permission.microphone);
        if (storageRequired) permissions.add(Permission.storage);

        /// ask for the permissions.
        await permissions.request();

        /// check the user gave us the permissions.
        granted = await Permission.microphone.isGranted &&
            await Permission.storage.isGranted;
        if (!granted) grantFailed(context);
      } else {
        granted = false;
        grantFailed(context);
      }
    } else
      granted = true;

    // we already have the required permissions.
    return granted;
  }

  /// Display a snackbar saying that we can't record due to lack of permissions.
  void grantFailed(BuildContext context) {
    var snackBar = SnackBar(
        content: Text(
            'Recording cannot start as you did not allow the required permissions'));

    // Find the Scaffold in the widget tree and use it to show a SnackBar.
    Scaffold.of(context).showSnackBar(snackBar);
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
