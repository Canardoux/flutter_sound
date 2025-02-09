---
title:  "Utilities API"
description: "isFFmpegAvailable()"
summary: "isFFmpegAvailable()"
permalink: tau_api_utilities_is_ffmpeg_available.html
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

----------------------------------------------------------------------------------------------------------------------------

## `isFFmpegAvailable()`

- Dart API: [isFFmpegAvailable()](pages/flutter-sound/api/helper/FlutterSoundHelper/isFFmpegAvailable.html)

This verb is used to know during runtime if FFmpeg is linked with the App.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        if ( await flutterSoundHelper.isFFmpegAvailable() )
        {
                Duration d = flutterSoundHelper.duration("$myFilePath/bar.wav");
        }
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------
