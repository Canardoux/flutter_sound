![pub version](https://img.shields.io/pub/v/taudio.svg?style=flat-square)
![Taudio](https://taudio.canardoux.xyz/images/Logotype-primary.png)

- ## `Taudio` user : your doc [is here](https://taudio.canardoux.xyz/)
- ## The CHANGELOG [is here](https://taudio.canardoux.xyz/tau/CHANGELOG.html)


## `Taudio` as a τ Project

`Taudio` is both :

- A wrapper above [Etau](https://pub.dev/packages/etau).
- [Flutter Sound v10.0](https://pub.dev/packages/flutter_sound).

`Taudio` is (will be) a complete rewrite of Flutter Sound 9.x. It keeps compatibility with the Flutter Sound 9.x API but will add a new wrapper above [Etau](https://pub.dev/packages/etau).

Taudio is actually in a developement state. There are many things to do before you can benefit of it. Specially:
- A documentation (TODO)
- A support of the three main platforms:
   - Web
   - iOS (TODO)
   - Android (TODO)

Actually, Taudio is essentially a new name for  Flutter Sound 10.0. It is 100% compatible with the Flutter Sound 9.x API. Later, the API wil be improved little by little for a more clean and modern API. It will be based on the Web Audio API as recommandated by the W3C.

Why `Taudio` and not `Flutter Sound 10.0.0 ? There are several reasons. Some are good and some are bad.
- Taudio is released under a different license. We wanted to be clear that it is a different product.
- Hopefully, the Flutter Sound legacy will decrease with time.
- Because issues on the Flutter Sound Github repository are a complete mess and I want to start a new clean Github repository.
- There are too many characters to type in Flutter Sound name.
- I am fed up with Flutter Sound and I need to work on something new.

The code and the doc are both to be done. Actually, you can refer to [the Flutter Sound doc](https://flutter-sound.canardoux.xyz/) if you need informations.

## The τ family

The `Tau` family begins to be rich :). It is composed by those following Flutter plugins.

- [Flutter Sound 9.x](https://flutter-sound.canardoux.xyz/) (the legacy plugin developed for many years)
- [Etau](https://pub.dev/packages/etau) (which is a port on Flutter Web of the W3C Web Audio API)
- [Tauweb](https://pub.dev/packages/tau_web) (which is the `Etau` implementation for Flutter Web)
- [Tauwar](https://pub.dev/packages/tau_war) (which is the `Etau` implementation for Flutter on mobiles)
- [Taudio](https://pub.dev/packages/taudio) (which is (will be) something like Flutter Sound 10.0)

![Architecture](https://taudio.canardoux.xyz/images/tau_architecture.png)

### [Flutter Sound](https://pub.dev/packages/flutter_sound)

This is the well known legacy 9.x package.

### [Etau](https://pub.dev/packages/etau)

This is (will be) an implementation on flutter of the [W3C Web Audio API](https://www.w3.org/TR/webaudio-1.1).
Etau is actually in a developement state. It is an Alpha version. Even not a Beta version. There are many things to do before you can use it. Specially:

- A documentation (TODO)
- A support of the main platforms:
   - Web
   - iOS (TODO)
   - Android (TODO)
   - The desktops (TODO)

The Web Audio API is terrific:

- It is a [W3C recommandation](https://www.w3.org/TR/webaudio-1.1)
- It has a great [documentation from Moziilla](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API)
- It is really powerful
- It is simple to use

Because the Web Audio API is a W3C recommandation, you can find very good documentations on the Web. Of course, the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) but also documentation from other sources.

In a few words, the Web Audio API let you assembly nodes as a Node Chain, from a Source Node (perhaps the mic), to a Destination Node (perhaps the speaker), threw several nodes able to process the sound (echo, analyzer, panner, distorder, ...). But you really should look to the Mozilla documentation which is very good.

Now, you will have to ask yourself if you must use [Taudio](https://pub.dev/packages/taudio) (which is just a wrapper around `Etau`), or directly [Etau](https://pub.dev/packages/etau).
The W3C recommandation is powerful but simple to use. There are probably no many reasons to use `Taudio` any longer.

`Etau` is (will be) released under the Gnu Public Licence v3 (GPL v3).

## License

- `Taudio` is released under the Gnu Public Licence v3 ([GPL v3](https://taudio.canardoux.xyz/tau/LICENSE.html))). The GPL license has a very strong copyleft clause. This mean that if you don't want, cannot or maynot release your App under a GPL License, you must stuck with Flutter Sound 9.x. This is not a big deal: Flutter Sound v 9.x will be maintain for a forseable future.
- `Taudio` is copyrighted by Canardoux.
- The Tau documentation is published under the [Creative Commons CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.en) license.

### But what is this famous GPL License ?

You can read all the [legally lines](http://localhost:4000/tau/LICENSE.html) if you want. But there are two main things that is important to understand :

- If your App is dependant of `Taudio`, you must publish the sources of your software somewhere. Probably on internet.

- If your App is dependant of `Taudio`, your App must be published under the GPL License too.

### Why is this License so good ?

Because you are perhaps a professional developer. I am a professional developer. If someone like me works freely for some companies it would not be fair for you. Why will your boss pay you, if other people work for free for them? Companies may use GPL software. But they have to give something in exchange.

## Taudio stands with Ukraine

![PeaceForUkraine](https://taudio.canardoux.xyz/images/2-year-old-irish-girl-ukrainian.jpg)
Peace for Ukraine

![PrayForUkraine](https://taudio.canardoux.xyz/images/banner.png)
Pray for Ukraine


## We need help

{: .important }
We greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation.

Actually, I am almost alone to maintain and develop three important projects :
- Etau
- Flutter Sound 9.x
- Taudio (flutter Sound 10.0)

This is too much on my shoulders. We desesperatly need at least one other developer.

## Thanks

{: .note }
### If you like my work, you can click on the `Thumb up` button of the top of the [pub.dev page](https://pub.dev/packages/flutter_sound).
This is free and this will reassure me that **I do not spend most of my life for nobody**.
