---
title:  "Audio Graphs"
description: "Graphs overview"
summary: "What is a &tau; audio Graph ?"
permalink: guides_graph.html
tags: [guides]
keywords: Audio Graph
---

## Audio-graphs

Audio-graph is a global object composed with several audio-nodes linked together.
For example, you connect the Microphone node to the Equalizer node, and the Equalizer node to the Headset node.

My dream isPerhaps in future we will also be able to create a graphic-editor to be be able to draw the audio-graph with the mouse.
The graphic editor will generate both a Dart (or Javascript) module and a visual SVG image that the &tau; user will be able to insert in its own documentation.

It will also generate a graph representation in an external format (JSON?), that you will be able to load during run-time inside your App.

{% include tip.html content="I guess that some App, will not want to **hard code** their audio-graph during development time,
but will want to allow their own end-user to define their audio-graph to be run.
Those App will provide their own graph editor, or perhaps will provide the &tau; graph editor to the end user.
The end user will _draw_ their own graph on their personal computer." %}

{% include note.html content="If we want that a normal end-user can use this editor, this editor must not be too technical.
Something powerful but usable by someone who has no computer notion." %}

### Examples

{% include image.html file="graph_examples.svg"  caption="Some Audio-Graph examples" %}

