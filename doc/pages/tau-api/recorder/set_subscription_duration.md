---
title:  "Recorder API"
description: "setSubscriptionDuration()"
summary: "setSubscriptionDuration()"
permalink: tau_api_recorder_set_subscription_duration.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API

---------------------------------------------------------------------------------------------------------------------------------

## `setSubscriptionDuration()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/setSubscriptionDuration.html)

This verb is used to change the default interval between two post on the "Update Progress" stream. (The default interval is 0 (zero) which means "NO post")

*Example:*
```dart
// 0. is default
myRecorder.setSubscriptionDuration(0.010);
```
