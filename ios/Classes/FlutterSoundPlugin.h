#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>

// this enum MUST be synchronized with lib/flutter_sound.dart and fluttersound/AudioInterface.java
typedef enum
{
       DEFAULT
     , CODEC_AAC
     , CODEC_OPUS
     , CODEC_CAF_OPUS // Apple encapsulates its bits in its own special envelope : .caf instead of a regular ogg/opus (.opus). This is completely stupid, this is Apple.
     , CODEC_MP3
     , CODEC_VORBIS
     , CODEC_PCM
} t_CODEC;

@interface FlutterSoundPlugin : NSObject<FlutterPlugin, AVAudioPlayerDelegate>
{
        AVAudioPlayer *audioPlayer;
}
- (FlutterMethodChannel*) getChannel;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
- (void)updateProgress: (NSTimer*)timer;
- (void)startTimer;
- (void)stopPlayer: (FlutterResult)result;
- (void)pausePlayer:(FlutterResult)result;
- (void)resumePlayer:(FlutterResult)result;
- (void)stopTimer;


@end
extern FlutterSoundPlugin* flutterSoundModule; // Singleton
