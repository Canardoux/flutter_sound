---
name: Problem Report
about: I got something wrong
title: "[BUG]:"
labels: Not yet handled, maybe bug
assignees: ''

---

## Flutter Sound Version : 

- **FULL** or **LITE** flavor ?

- **Important**: Result of the command : ```flutter pub deps | grep flutter_sound```

----------------------------------------------------------

## Severity

- Crash ?

- Result is not what expected ?

- Cannot build my App ?

- Minor issue ?

--------------------------------------------------------

## Platforms you faced the error 

- iOS ?

- Android ?

- Flutter Web ?

- Emulator ? 

- Real device ?

------------------------------------------------

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error
----------------------------------------------

# Logs!!!!
(**This is very important**. Most of the time we cannot do anything if we do not have information on your bug).
To activate the logs, you must instantiate your modules with the Log Level set to `Level.debug` :
```
FlutterSoundPlayer myPlayer = FlutterSoundPlayer(logLevel: Level.debug);
FlutterSoundRecorder myRecorder = FlutterSoundRecorder(logLevel: Level.debug);
```
See [this](https://tau.canardoux.xyz/logger.html)

-----------------------------------------------------------------
