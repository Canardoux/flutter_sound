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

typedef enum
{
        NOT_SET,
        FOR_PLAYING, // Flutter_sound did it during startPlayer()
        FOR_RECORDING, // Flutter_sound did it during startRecorder()
        BY_USER // The caller did it himself : flutterSound must not change that)
} t_SET_CATEGORY_DONE;

typedef enum
{
        IS_STOPPED,
        IS_PLAYING,
        IS_PAUSED,
        IS_RECORDING,
} t_AUDIO_STATE;


extern t_SET_CATEGORY_DONE setCategoryDone;
extern t_SET_CATEGORY_DONE setActiveDone;
extern bool isPaused ;



@interface FlutterSoundPlugin : NSObject<FlutterPlugin, AVAudioPlayerDelegate>
{
        AVAudioPlayer *audioPlayer;
}
- (FlutterMethodChannel*) getChannel;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
- (void)updateProgress: (NSTimer*)timer;
- (void)startTimer;
- (void)stopPlayer;
- (void)pausePlayer:(FlutterResult)result;
- (void)resumePlayer:(FlutterResult)result;
- (void)stopTimer;
- (void)pause;
- (bool)resume;


@end
extern FlutterSoundPlugin* flutterSoundModule; // Singleton
