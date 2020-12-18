---
title:  "A new &tau; documentation"
published: true
permalink: newdoc-post.html
summary: "The new &tau; documentation is now based on Jekyll."
tags: [jekyll]
---
The previous tool for the &tau; documentation was [Gitbook](https://www.gitbook.com/).
It was a bad choice :
- Gitbook used to be Free and Open Source (Apache license). But the free project is now deprecated. It has not been maintened for three years.
- Gitbook is now developed by a little french company but is not Open Source anymore. This happens with Free software not protected with a strong Free and Open Source license (GPL). This is what happens with license like MIT or Apache which are bad licenses.
- My thinking is that Flutter Sound must **NOT USE PROPRIETARY SOFTWARE**. This is a political choice.
- Gitbook is buggy. When we include an HTML page in the documentation, the page hyperlinks point to Github instead of the documentation.
- Impossible to include the pages produced by Dartdoc inside our documentation.
- The Free/Open Source version of Gitbook has High Security Alerts from Github. This is not acceptable.

The major challenge was to find a tool that can integrate smoothly the `Dartdoc Documentation`. The Dartdoc documentation is just HTML pages instead of Markdown.
I investigated many documentation tools (Hugo, Gatsby, JustTheDoc, docsy, docusaurus, ...), but all those tools was not compatible with Dartdoc.

I really wanted the following features :
- The user can browse the API reference documentation ([Dartdoc Documentation](dartdoc.html)) from the Flutter Sound documentation without opening a new browser tab, and return to the flutter documentation with the Browser Back button.
- The API reference documentation must display the Flutter Sound documentation top navigation bar.
- The user can display the left navigation bar on Dartdoc pages, so that he/she will never be lost.
- The user can choice to display or hide this left navigation bar if he/she has a narrow screen

The only tool I found which met my required features is [Jekyll](https://jekyllrb.com/), with the [Documentation Theme for Jekyll](https://idratherbewriting.com/documentation-theme-jekyll/index.html).
This tool is not perfect. Far from that. But it allows the pages produced by Dartdoc to be integrated inside our documentation.

I hope that this time the choice is correct : I spent too much time on the documentation tool, instead of the documentation content itself.

Please, let ne know if you have remarks on this.
