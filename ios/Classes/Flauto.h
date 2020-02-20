#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import "FlutterSoundPlugin.h"

@interface Flauto : FlutterSoundPlugin // NSObject<FlutterPlugin, AVAudioPlayerDelegate>
//+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

-(FlutterMethodChannel*) getChannel;

@end
extern Flauto* flautoModule; // Singleton
