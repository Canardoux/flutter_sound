# Pub-compatible example assets

Based on zeqinjie/flutter_sound feature/swift_package_manager at ae3b4ee3bbfa89cd4b958b3f479b9b8717a9b9a2.

The seven example/web/js symlinks pointed outside the Git repository into a sibling flutter_sound_web checkout. Fresh Pub Git dependency downloads reject these links. Replace them with regular files from the matching flutter_sound_web 9.30.0 package, preserving the example assets without depending on a sibling checkout. Existing source license headers remain intact.
