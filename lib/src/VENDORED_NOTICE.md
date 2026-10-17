These directories contain code derived from:

- [flutter_sound_platform_interface 10.3.8](https://github.com/canardoux/flutter_sound_platform_interface) (`fs_platform/`)
- [flutter_sound_web 10.3.8](https://github.com/canardoux/flutter_sound_web) (`fs_web/` and `web_assets/`)

Original copyright headers are retained. The copies are modified: package URIs now point at `flutter_sound_advanced`, and logging goes through `fs_logger_compat.dart` so web/WASM uses `package:logger/web.dart` instead of `package:logger/logger.dart`.

Licensed under the Mozilla Public License 2.0. See `/LICENSE`.
