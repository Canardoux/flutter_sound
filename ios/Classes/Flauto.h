#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import "FlutterSoundPlugin.h"

@interface Flauto : FlutterSoundPlugin // NSObject<FlutterPlugin, AVAudioPlayerDelegate>

-(FlutterMethodChannel*) getChannel;

@end
extern Flauto* flautoModule; // Singleton
