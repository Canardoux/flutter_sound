#import "FlutterSoundPlugin.h"
#import "Track.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

NSString* defaultExtensions [] =
{
    @"sound.aac" 	// CODEC_DEFAULT
    @"sound.aac" 	// CODEC_AAC
    , @"sound.opus"	// CODEC_OPUS
    , @"sound.caf"	// CODEC_CAF_OPUS
    , @"sound.mp3"	// CODEC_MP3
    , @"sound.ogg"	// CODEC_VORBIS
    , @"sound.wav"	// CODE_PCM
};

AudioFormatID formats [] =
{
    kAudioFormatMPEG4AAC	// CODEC_DEFAULT
    , kAudioFormatMPEG4AAC	// CODEC_AAC
    , 0						// CODEC_OPUS
    , kAudioFormatOpus		// CODEC_CAF_OPUS
    , 0						// CODEC_MP3
    , 0						// CODEC_OGG
    , 0						// CODEC_PCM
};


bool _isIosEncoderSupported [] =
{
    true, // DEFAULT
    true, // AAC
    false, // OGG/OPUS
    true, // CAF/OPUS
    false, // MP3
    false, // OGG/VORBIS
    false, // WAV/PCM
};


bool _isIosDecoderSupported [] =
{
    true, // DEFAULT
    true, // AAC
    false, // OGG/OPUS
    true, // CAF/OPUS
    true, // MP3
    false, // OGG/VORBIS
    true, // WAV/PCM
};


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
NSString* GetDirectoryOfType_FlutterSound(NSSearchPathDirectory dir) {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
    return [paths.firstObject stringByAppendingString:@"/"];
}

@implementation FlutterSoundPlugin{
    NSURL *audioFileURL;
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    NSTimer *timer;
    NSTimer *dbPeakTimer;
    Track *track;
}
int PLAYING_STATE = 0;
int PAUSED_STATE = 1;
int STOPPED_STATE = 2;
double subscriptionDuration = 0.01;
double dbPeakInterval = 0.8;
bool shouldProcessDbLevel = false;
FlutterMethodChannel* _channel;

bool isPlaying = false;
BOOL includeAPFeatures = false;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"audioPlayerDidFinishPlaying");
    // Get the duration of the current audio file
    NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
    // Get the duration of the current audio file
    NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];
    
    // Compose a string containing the status of the playback with duration and current position
    NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
    /*
     NSDictionary *status = @{
     @"duration" : [duration stringValue],
     @"current_position" : [currentTime stringValue],
     };
     */
    [_channel invokeMethod:@"audioPlayerDidFinishPlaying" arguments:status];
    
    // The audio file has finished playing, so we can stop the timer
    [self stopTimer];
}

- (void) stopTimer{
    // Invalidate the timer if it is valid
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)updateRecorderProgress:(NSTimer*) timer
{
    NSNumber *currentTime = [NSNumber numberWithDouble:audioRecorder.currentTime * 1000];
    [audioRecorder updateMeters];
    
    NSString* status = [NSString stringWithFormat:@"{\"current_position\": \"%@\"}", [currentTime stringValue]];
    /*
     NSDictionary *status = @{
     @"current_position" : [currentTime stringValue],
     };
     */
    
    [_channel invokeMethod:@"updateRecorderProgress" arguments:status];
}

- (void)updateProgress:(NSTimer*) timer
{
    // Get the duration of the current audio file
    NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
    // Get the current position in the current audio file
    NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];
    
    // If the duration is null but the timer was started, stop it
    if ([duration intValue] == 0 && timer != nil) {
        [self stopTimer];
        return;
    }
    
    // Compose a string containing the status of the playback with duration and current position
    NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
    /*
     NSDictionary *status = @{
     @"duration" : [duration stringValue],
     @"current_position" : [currentTime stringValue],
     };
     */
    
    // Pass the string containing the status of the playback to the native code
    [_channel invokeMethod:@"updateProgress" arguments:status];
}

- (void)updateDbPeakProgress:(NSTimer*) dbPeakTimer
{
    NSNumber *normalizedPeakLevel = [NSNumber numberWithDouble:MIN(pow(10.0, [audioRecorder peakPowerForChannel:0] / 20.0) * 160.0, 160.0)];
    [_channel invokeMethod:@"updateDbPeakProgress" arguments:normalizedPeakLevel];
}

- (void)startRecorderTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->timer = [NSTimer scheduledTimerWithTimeInterval: subscriptionDuration
                                                       target:self
                                                     selector:@selector(updateRecorderProgress:)
                                                     userInfo:nil
                                                      repeats:YES];
    });
}

- (void)startTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->timer = [NSTimer scheduledTimerWithTimeInterval:subscriptionDuration
                                                       target:self
                                                     selector:@selector(updateProgress:)
                                                     userInfo:nil
                                                      repeats:YES];
    });
}

- (void)startDbTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->dbPeakTimer = [NSTimer scheduledTimerWithTimeInterval:dbPeakInterval
                                                             target:self
                                                           selector:@selector(updateDbPeakProgress:)
                                                           userInfo:nil
                                                            repeats:YES];
    });
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_sound"
                                     binaryMessenger:[registrar messenger]];
    FlutterSoundPlugin* instance = [[FlutterSoundPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    _channel = channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"startRecorder" isEqualToString:call.method]) {
        NSString* path = (NSString*)call.arguments[@"path"];
        NSNumber* sampleRateArgs = (NSNumber*)call.arguments[@"sampleRate"];
        NSNumber* numChannelsArgs = (NSNumber*)call.arguments[@"numChannels"];
        NSNumber* iosQuality = (NSNumber*)call.arguments[@"iosQuality"];
        NSNumber* bitRate = (NSNumber*)call.arguments[@"bitRate"];
        NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
        
        t_CODEC coder = CODEC_AAC;
        if (![codec isKindOfClass:[NSNull class]])
        {
            coder = [codec intValue];
        }
        
        float sampleRate = 44100;
        if (![sampleRateArgs isKindOfClass:[NSNull class]]) {
            sampleRate = [sampleRateArgs integerValue];
        }
        
        int numChannels = 2;
        if (![numChannelsArgs isKindOfClass:[NSNull class]]) {
            numChannels = [numChannelsArgs integerValue];
        }
        
        [self startRecorder:path:[NSNumber numberWithInt:numChannels]:[NSNumber numberWithInt:sampleRate]:coder:iosQuality:bitRate result:result];
        
    } else if ([@"isEncoderSupported" isEqualToString:call.method]) {
        NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
        [self isEncoderSupported:[codec intValue] result:result];
    } else if ([@"isDecoderSupported" isEqualToString:call.method]) {
        NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
        [self isDecoderSupported:[codec intValue] result:result];
    } else if ([@"stopRecorder" isEqualToString:call.method]) {
        [self stopRecorder: result];
    } else if ([@"startPlayer" isEqualToString:call.method]) {
        NSDictionary* trackDict = (NSDictionary*) call.arguments[@"track"];
        track = [[Track alloc] initFromDictionary:trackDict];
       
       BOOL canSkipForward = [call.arguments[@"canSkipForward"] boolValue];
       BOOL canSkipBackward = [call.arguments[@"canSkipBackward"] boolValue];
        
        [self startPlayer:canSkipForward canSkipBackward:canSkipBackward result:result];
    } else if ([@"stopPlayer" isEqualToString:call.method]) {
        [self stopPlayer:result];
    } else if ([@"pausePlayer" isEqualToString:call.method]) {
        [self pausePlayer:result];
    } else if ([@"resumePlayer" isEqualToString:call.method]) {
        [self resumePlayer:result];
    } else if ([@"seekToPlayer" isEqualToString:call.method]) {
        NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
        [self seekToPlayer:sec result:result];
    } else if ([@"setSubscriptionDuration" isEqualToString:call.method]) {
        NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
        [self setSubscriptionDuration:[sec doubleValue] result:result];
    } else if ([@"setVolume" isEqualToString:call.method]) {
        NSNumber* volume = (NSNumber*)call.arguments[@"volume"];
        [self setVolume:[volume doubleValue] result:result];
    }
    else if ([@"setDbPeakLevelUpdate" isEqualToString:call.method]) {
        NSNumber* intervalInSecs = (NSNumber*)call.arguments[@"intervalInSecs"];
        [self setDbPeakLevelUpdate:[intervalInSecs doubleValue] result:result];
    }
    else if ([@"setDbLevelEnabled" isEqualToString:call.method]) {
        BOOL enabled = [call.arguments[@"enabled"] boolValue];
        [self setDbLevelEnabled:enabled result:result];
    } else if ([@"initializeMediaPlayer" isEqualToString:call.method]) {
        BOOL includeAudioPlayerFeatures = [call.arguments[@"includeAudioPlayerFeatures"] boolValue];
        
        [self initializeMediaPlayer:includeAudioPlayerFeatures result:result];
    } else if ([@"releaseMediaPlayer" isEqualToString:call.method]) {
        [self releaseMediaPlayer:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}


- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result {
    NSNumber*  b = [NSNumber numberWithBool: _isIosDecoderSupported[codec] ];
    result(b);
}

- (void)isEncoderSupported:(t_CODEC)codec result: (FlutterResult)result {
    NSNumber*  b = [NSNumber numberWithBool: _isIosEncoderSupported[codec] ];
    result(b);
}

- (void)setSubscriptionDuration:(double)duration result: (FlutterResult)result {
    subscriptionDuration = duration;
    result(@"setSubscriptionDuration");
}

- (void)setDbPeakLevelUpdate:(double)intervalInSecs result: (FlutterResult)result {
    dbPeakInterval = intervalInSecs;
    result(@"setDbPeakLevelUpdate");
}

- (void)setDbLevelEnabled:(BOOL)enabled result: (FlutterResult)result {
    shouldProcessDbLevel = enabled == YES;
    result(@"setDbLevelEnabled");
}

- (void)startRecorder
        :(NSString*)path
        :(NSNumber*)numChannels
        :(NSNumber*)sampleRate
        :(t_CODEC) codec
        :(NSNumber*)iosQuality
        :(NSNumber*)bitRate
        result: (FlutterResult)result {
  if ([path class] == [NSNull class]) {
    audioFileURL = [NSURL fileURLWithPath:[GetDirectoryOfType_FlutterSound(NSCachesDirectory) stringByAppendingString:defaultExtensions[codec] ]];
  } else {
    audioFileURL = [NSURL fileURLWithPath: path];
  }
  NSMutableDictionary *audioSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithFloat:[sampleRate doubleValue]],AVSampleRateKey,
                                 [NSNumber numberWithInt: formats[codec] ],AVFormatIDKey,
                                 [NSNumber numberWithInt: [numChannels intValue]],AVNumberOfChannelsKey,
                                 [NSNumber numberWithInt: [iosQuality intValue]],AVEncoderAudioQualityKey,
                                 nil];
    
    // If bitrate is defined, the use it, otherwise use the OS default
    if(![bitRate isEqual:[NSNull null]]) {
        [audioSettings setValue:[NSNumber numberWithInt: [bitRate intValue]]
                         forKey:AVEncoderBitRateKey];
    }
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // set volume default to speaker
    UInt32 doChangeDefaultRoute = 1;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);
    
    // set up for bluetooth microphone input
    UInt32 allowBluetoothInput = 1;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,sizeof (allowBluetoothInput),&allowBluetoothInput);
    
    audioRecorder = [[AVAudioRecorder alloc]
                     initWithURL:audioFileURL
                     settings:audioSettings
                     error:nil];
    
    [audioRecorder setDelegate:self];
    [audioRecorder record];
    [self startRecorderTimer];
    
    [audioRecorder setMeteringEnabled:shouldProcessDbLevel];
    if(shouldProcessDbLevel == true) {
        [self startDbTimer];
    }
    
    NSString *filePath = self->audioFileURL.path;
    result(filePath);
}

- (void)stopRecorder:(FlutterResult)result {
    [audioRecorder stop];
    
    // Stop Db Timer
    [dbPeakTimer invalidate];
    dbPeakTimer = nil;
    [self stopTimer];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    
    NSString *filePath = audioFileURL.absoluteString;
    result(filePath);
}

- (void)startPlayer:(BOOL)canSkipForward canSkipBackward: (BOOL)canSkipBackward result: (FlutterResult)result {
    if(!track) {
        result([FlutterError errorWithCode:@"UNAVAILABLE"
                                   message:@"The track passed to startPlayer is not valid."
                                   details:nil]);
    }
    
    
    // Check whether the audio file is stored as a path to a file or a buffer
    if([track isUsingPath]) {
        // The audio file is stored as a path to a file
        
        NSString *path = track.path;
        
        bool isRemote = false;
        // Check whether a path was given
        if ([path class] == [NSNull class]) {
            // No path was given, get the path to a default sound
            audioFileURL = [NSURL fileURLWithPath:[GetDirectoryOfType_FlutterSound(NSCachesDirectory) stringByAppendingString:@"sound.aac"]];
        } else {
            // A path was given, then create a NSURL with it
            NSURL *remoteUrl = [NSURL URLWithString:path];
            
            // Check whether the URL points to a local or remote file
            if(remoteUrl && remoteUrl.scheme && remoteUrl.host){
                audioFileURL = remoteUrl;
                isRemote = true;
            } else {
                audioFileURL = [NSURL URLWithString:path];
            }
        }
        
        // Check whether the file path poits to a remote or local file
        if (isRemote) {
            NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                                  dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                      // NSData *data = [NSData dataWithContentsOfURL:audioFileURL];
                                                      
                                                      // The file to play has been downloaded, then initialize the audio player
                                                      // and start playing.
                                                      
                                                      // We must create a new Audio Player instance to be able to play a different Url
                                                      self->audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
                                                      self->audioPlayer.delegate = self;
                                                      
                                                      // Able to play in silent mode
                                                      [[AVAudioSession sharedInstance]
                                                       setCategory: AVAudioSessionCategoryPlayback
                                                       error: nil];
                                                      // Able to play in background
                                                      [[AVAudioSession sharedInstance] setActive: YES error: nil];
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                                                      });
                                                      
                                                      [self->audioPlayer play];
                                                      [self startTimer];
                                                      NSString *filePath = self->audioFileURL.absoluteString;
                                                      result(filePath);
                                                  }];
            
            [downloadTask resume];
        } else {
            // Initialize the audio player with the file that the given path points to,
            // and start playing.
            
            // if (!audioPlayer) { // Fix sound distoring when playing recorded audio again.
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
            audioPlayer.delegate = self;
            // }
            
            // Able to play in silent mode
            [[AVAudioSession sharedInstance]
             setCategory: AVAudioSessionCategoryPlayback
             error: nil];
            
            [audioPlayer play];
            [self startTimer];
            NSString *filePath = audioFileURL.absoluteString;
            result(filePath);
        }
    } else {
        // The audio file is stored as a buffer
        FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*) track.dataBuffer;
        NSData* bufferData = [dataBuffer data];
        audioPlayer = [[AVAudioPlayer alloc] initWithData: bufferData error: nil];
        audioPlayer.delegate = self;
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
        [audioPlayer play];
        [self startTimer];
        result(@"Playing from buffer");
    }
    
    isPlaying = true;
    NSNumber *playingState = [NSNumber numberWithInt:PLAYING_STATE];
    [_channel invokeMethod:@"updatePlaybackState" arguments:playingState];
    
    // Display the notification with the media controls
    if (includeAPFeatures) {
      [self setupRemoteCommandCenter:canSkipForward   canSkipBackward:canSkipBackward result:result];
      [self setupNowPlaying:nil];
    }
}

- (void)stopPlayer:(FlutterResult)result {
    // Check whether the audio player is valid
    if (audioPlayer) {
        // The audio player is valid, then stop it
        [audioPlayer stop];
        
        isPlaying = false;
        
        NSNumber *stoppedState = [NSNumber numberWithInt:STOPPED_STATE];
        [_channel invokeMethod:@"updatePlaybackState" arguments:stoppedState];
        
        result(@"stop play");
    } else {
        // The audio player is not valid, then throw an error
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

- (void)pausePlayer:(FlutterResult)result {
    // Check whether the player is valid and is playing
    if (audioPlayer && [audioPlayer isPlaying]) {
        // The player is valid and is playing, then pause it and invalidate the timer
        [audioPlayer pause];
        if (timer != nil) {
            [timer invalidate];
            timer = nil;
        }
        
        isPlaying = false;
        
        NSNumber *pausedState = [NSNumber numberWithInt:PAUSED_STATE];
        [_channel invokeMethod:@"updatePlaybackState" arguments:pausedState];
        
        result(@"pause play");
    } else {
        // The player is not valid or is not playing, then throw an error
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

- (void)resumePlayer:(FlutterResult)result {
    // Throw an error if the audio file path was not given
    if (!audioFileURL) {
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"fileURL is not defined"
                details:nil]);
        return;
    }
    
    // Throw an error if the audio player is not valid
    if (!audioPlayer) {
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
        return;
    }
    
    // Resume the player and the timer
    [[AVAudioSession sharedInstance]
     setCategory: AVAudioSessionCategoryPlayback
     error: nil];
    [audioPlayer play];
    [self startTimer];
    
    isPlaying = true;
    NSNumber *playingState = [NSNumber numberWithInt:PLAYING_STATE];
    [_channel invokeMethod:@"updatePlaybackState" arguments:playingState];
    
    NSString *filePath = audioFileURL.absoluteString;
    result(filePath);
}

- (void)seekToPlayer:(nonnull NSNumber*) time result: (FlutterResult)result {
    // Check whether the audio player is valid
    if (audioPlayer) {
        // Set the new position in milliseconds
        audioPlayer.currentTime = [time doubleValue] / 1000;
        // Send update to the native code
        [self updateProgress:nil];
        result([time stringValue]);
    } else {
        // Throw an error if the audio player is not valid
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

- (void)setVolume:(double) volume result: (FlutterResult)result {
    if (audioPlayer) {
        [audioPlayer setVolume: volume];
        result(@"volume set");
    } else {
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

// Give the system information about what the audio player
// is currently playing. Takes in the image to display in the
// notification to control the media playback.
- (void)setupNowPlaying:(MPMediaItemArtwork*)albumArt{
    // Initialize the MPNowPlayingInfoCenter
    
    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    
    // Check whether an album art was given
    if(albumArt == nil) {
        // No images were given, then retrieve the album art for the
        // current track and, when retrieved, update these
        // information again.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = [NSURL URLWithString:self->track.albumArt];
            
            UIImage *artworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            if(artworkImage)
            {
                MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                
                [self setupNowPlaying:albumArt];
            }
        });
    } else {
        // An image was given, then display it among the track information
        [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
    }
    
    NSNumber *progress = [NSNumber numberWithDouble:audioPlayer.currentTime];
    NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration];
    
    [songInfo setObject:track.title forKey:MPMediaItemPropertyTitle];
    [songInfo setObject:track.author forKey:MPMediaItemPropertyArtist];
    [songInfo setObject:progress forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [songInfo setObject:duration forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:[NSNumber numberWithDouble:(isPlaying ? 1.0f : 0.0f)] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    [playingInfoCenter setNowPlayingInfo:songInfo];
}

// Give the system information about what to do when the notification
// control buttons are pressed.
- (void)setupRemoteCommandCenter:(BOOL)canSkipForward canSkipBackward: (BOOL)canSkipBackward result: (FlutterResult)result {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.togglePlayPauseCommand setEnabled:YES];
    [commandCenter.nextTrackCommand setEnabled:canSkipForward];
    [commandCenter.previousTrackCommand setEnabled:canSkipBackward];
    
    [commandCenter.togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if(isPlaying) {
            [self pausePlayer: result];
        } else {
            [self resumePlayer: result];
        }
        
        // [[MediaController sharedInstance] playOrPauseMusic];    // Begin playing the current track.
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    
    // [commandCenter.playCommand setEnabled:YES];
    // [commandCenter.pauseCommand setEnabled:YES];
    //   [commandCenter.playCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
    //       // [[MediaController sharedInstance] playOrPauseMusic];    // Begin playing the current track.
    //       [self resumePlayer:result];
    //       return MPRemoteCommandHandlerStatusSuccess;
    //   }];
    //
    //   [commandCenter.pauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
    //       // [[MediaController sharedInstance] playOrPauseMusic];    // Begin playing the current track.
    //       [self pausePlayer:result];
    //       return MPRemoteCommandHandlerStatusSuccess;
    //   }];
    
    [commandCenter.nextTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [_channel invokeMethod:@"skipForward" arguments:nil];
        // [[MediaController sharedInstance] fastForward];    // forward to next track.
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.previousTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [_channel invokeMethod:@"skipBackward" arguments:nil];
        // [[MediaController sharedInstance] rewind];    // back to previous track.
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

-(void)initializeMediaPlayer:(BOOL)includeAudioPlayerFeatures result: (FlutterResult)result {
    // Set whether we have to include the audio player features
    includeAPFeatures = includeAudioPlayerFeatures;
    // No further initialization is needed for the iOS audio player, then exit
    // the method.
    result(@"The player had already been initialized.");
}

- (void)releaseMediaPlayer:(FlutterResult)result {
    // Invalidate the timer and the audio player
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    audioPlayer = nil;
    
    result(@"The player has been successfully released");
}

@end
