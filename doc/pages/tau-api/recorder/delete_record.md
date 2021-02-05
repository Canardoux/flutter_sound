---
title:  "Recorder API"
description: "deleteRecord()"
summary: "deleteRecord()"
permalink: tau_api_recorder_delete_record.html
tags: [api,recorder]
keywords: API Recorder
---
# The &tau; Recorder API

------------------------------------------------------------------------------------------------------------------------

## deleteRecord()

- Dart API: [deleteRecord](pages/flutter-sound/api/recorder/FlutterSoundRecorder/deleteRecord.html)

Delete a temporary file created during [startRecorder()].

This function is seldom used, because [closeAudioSession()] delete automaticaly
all the temporary files created.


*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        await myRecorder.startRecorder(toFile: 'foo'); // This is a temporary file, because no slash '/' in the argument
        await myPlayer.startPlayer(fromURI: 'foo');
        await myRecorder.deleteRecord('foo');
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>


--------------------------------------------------------------------------------------------------------------------------
