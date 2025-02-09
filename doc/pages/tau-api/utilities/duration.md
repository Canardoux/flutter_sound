---
title:  "Utilities API"
description: "duration()"
summary: "duration()"
permalink: tau_api_utilities_duration.html
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

----------------------------------------------------------------------------------------------------------------------------

## `duration()`

- Dart API: [duration()](pages/flutter-sound/api/helper/FlutterSoundHelper/duration.html)

This verb is used to get an estimation of the duration of a sound file.
Be aware that it is just an estimation, based on the Codec used and the sample rate.

Note : this verb uses FFmpeg and is not available int the LITE flavor of Flutter Sound.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        Duration d = flutterSoundHelper.duration("$myFilePath/bar.wav");
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

----------------------------------------------------------------------------------------------------------------------------
