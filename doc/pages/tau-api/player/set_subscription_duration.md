---
title:  "Player API"
description: "setSubscriptionDuration()"
summary: "setSubscriptionDuration()"
permalink: tau_api_player_set_subscription_duration.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `setSubscriptionDuration()`

- Dart API: [setSubscriptionDuration()](pages/flutter-sound/api/player/FlutterSoundPlayer/setSubscriptionDuration.html).

This verb is used to change the default interval between two post on the "Update Progress" stream. (The default interval is 0 (zero) which means "NO post")

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        myPlayer.setSubscriptionDuration(Duration(milliseconds: 100));
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>
