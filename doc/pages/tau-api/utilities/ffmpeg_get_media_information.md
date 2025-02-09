---
title:  "Utilities API"
description: "ffMpegGetMediaInformation()"
summary: "ffMpegGetMediaInformation()"
permalink: tau_api_utilities_ffmpeg_get_media_information.html
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

---------------------------------------------------------------------------------------------------------------------------

## `ffMpegGetMediaInformation()`

- Dart API: [ffMpegGetMediaInformation()](pages/flutter-sound/api/helper/FlutterSoundHelper/ffMpegGetMediaInformation.html)

This verb is used to get various informations on a file.

The informations got with FFmpegGetMediaInformation() are [documented here](https://pub.dev/packages/flutter_ffmpeg).

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        print( await getLastFFmpegCommandOutput() );
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Map<dynamic, dynamic> info = await flutterSoundHelper.FFmpegGetMediaInformation( uri );
</pre>
</div>

</div>
