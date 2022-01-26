---
title:  "Flutter FFmpeg"
description: "Lite flavor vs Full flavor"
summary: "Flutter FFmpeg compatibility."
permalink: guides_lite-full.html
tags: [flutter_sound]
keywords: Flutter, &tau;
---
# No more FULL/LITE flavor.

Starting with Flutter Sound 9.0, we do not have anymore two flavors.

Flutter Sound is not linked anymore with Mobile FFmpeg.
We do not have anymore automatic Audio Format conversions.

If the App wants to convert some of its records,
it must depend itself on Flutter FFmpeg and call itself the apropriate function.

