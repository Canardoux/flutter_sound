---
title:  "Utilities API"
description: "executeFFmpegWithArguments()"
summary: "executeFFmpegWithArguments()"
permalink: tau_api_utilities_execute_ffmpeg_with_arguments.html
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

---------------------------------------------------------------------------------------------------------------------------

## `executeFFmpegWithArguments()`

- Dart API: [executeFFmpegWithArguments()](pages/flutter-sound/api/helper/FlutterSoundHelper/executeFFmpegWithArguments.html)

This verb is a wrapper for the great FFmpeg application.
The command *"man ffmpeg"* (if you have installed ffmpeg on your computer) will give you many informations.
If you do not have `ffmpeg` on your computer you will find easyly on internet many documentation on this great program.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
int rc = await flutterSoundHelper.executeFFmpegWithArguments
 ([
        '-loglevel',
        'error',
        '-y',
        '-i',
        infile,
        '-c:a',
        'copy',
        outfile,
]); // remux OGG to CAF
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------
