---
title:  "Recorder API"
description: "setSubscriptionDuration()"
summary: "setSubscriptionDuration()"
permalink: tau_api_recorder_set_subscription_duration.html
tags: [api,recorder]
keywords: API Recorder
---
# The &tau; Recorder API

---------------------------------------------------------------------------------------------------------------------------------

## `setSubscriptionDuration()`

- Dart API: [setSubscriptionDuration](pages/flutter-sound/api/recorder/FlutterSoundRecorder/setSubscriptionDuration.html)

This verb is used to change the default interval between two post on the "Update Progress" stream. (The default interval is 0 (zero) which means "NO post")

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        // 0 is default
        myRecorder.setSubscriptionDuration(0.010);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>
