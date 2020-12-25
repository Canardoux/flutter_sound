---
title:  "Player API"
description: "isDecoderSupported()"
summary: "isDecoderSupported()"
permalink: tau_api_player_is_decoder_supported.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `isDecoderSupported()`


- Dart API: [isDecoderSupported()](pages/flutter-sound/api/player/FlutterSoundPlayer/isDecoderSupported.html).

This verb is useful to know if a particular codec is supported on the current platform.
Returns a Future<bool>.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
         if ( await myPlayer.isDecoderSupported(Codec.opusOGG) ) doSomething;
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
