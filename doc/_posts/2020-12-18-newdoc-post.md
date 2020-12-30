---
title:  "A new &tau; documentation"
published: true
permalink: newdoc-post.html
summary: "The new &tau; documentation is now based on Jekyll."
tags: [jekyll,news]
---

## 1. Jekyll

The previous tool for the &tau; documentation was [Gitbook](https://www.gitbook.com/).
It was a bad choice :
- Gitbook used to be Free and Open Source (Apache license). But the free project is now deprecated. It has not been maintened for three years.
- Gitbook is now developed by a little french company but is not Open Source anymore. This happens with Free software not protected with a strong Free and Open Source license (GPL). This is what happens with license like MIT or Apache which are bad licenses.
- My thinking is that Flutter Sound must **NOT USE PROPRIETARY SOFTWARE**. This is a political choice.
- Gitbook is buggy. When we include an HTML page in the documentation, the page hyperlinks point to Github instead of the documentation.
- Impossible to include the pages produced by Dartdoc inside our documentation.
- The Free/Open Source version of Gitbook has High Security Alerts from Github. This is not acceptable.

The major challenge was to find a tool that can integrate smoothly the Dartdoc Documentation. The Dartdoc documentation is just HTML pages instead of Markdown.
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


## 2. The Version 7.4

I did a terrible mistake : the master branch is now named 7.4.9 instead of 6.4.9 Impossible to correct that on pub.dev: a commit is for ever. I am confused :-( .

I suggest that Flutter Sound users stay on 6.4 .  The version 6.4 will be the real current version released and supported.
The version 7.x  will be the future version and will not be background compatible with V6.


## 3. A Roadmap

Actually, the Flutter Sound issues are a complete mess.
Everybody create new issues sometimes for bugs, sometimes for asking help, sometimes to request new features.
But nobody can have a clear visibility of the actual situation.

Actually there is 71 issues open. And probably there will be more next week. I cannot manage that all by myself alone.
The deficiency of Flutter Sound developers is a big problem.

I am not satisfied with the way Github manage the _issues_. I am thinking to setup a real Bug Tracker.
Something like Mantis, Trac, Bugzilla or Jira. But I worry that those tools are really good to manage
a project with a real team. Actually Flutter Sound has no team. So nobody to be managed.

I suggest that for now we keep _Github_ and use [the Projects feature](https://github.com/dooboolab/flutter_sound/projects/3) for trying
to have a better visibility of
- what must be done (first column),
- what is planned (second column),
- what is in progress (third column)
- and what is done (fourth column).

I will try to keep the number of issues planned (second column) not too high, and order this column from **high** priority to **low** priority.

When an issue will be registered in the _Project_ table, I will close it.
An issue closed will not be necessary fixed, but we will be sure that it is entered somewhere in the planning.
Note: the _Project_ table can point to close issues, so this is not a problem to close them.

Something not clear for me, is how the Flutter Sound users can influence the issues that are planned, and the priority of those planned issues.
There is three possibilities :
- The Flutter Sound user can post remarks in issues to help me to know what is important or not
- The Flutter Sound user can use the _Discussions_ as a forum to discuss what must me done.
- Use the Github Wiki

I do not understand why the Github _Discussions_ feature is not used by Flutter Sound users.
If necessary, we can setup a real forum like PhpBB, MyBB, or Discourse. But probably better to try to use the current tool (Github) before seting up something new.

