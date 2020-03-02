/*
 * flauto is a flutter_sound module.
 * flutter_sound is distributed with a MIT License
 *
 * Copyright (c) 2018 dooboolab
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 */

/*
 * flauto is a flutter_sound module.
 * Its purpose is to offer higher level functionnalities, using MediaService/MediaBrowser.
 * This module may use flutter_sound module, but flutter_sound module may not depends on this module.
 */

#import "flauto.h"
#import "FlutterSoundPlugin.h"
#import "Track.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>


 @implementation Flauto {
    NSURL *audioFileURL;
    Track *track;
    id forwardTarget;
    id backwardTarget;
    id pauseTarget;
 }
int PLAYING_STATE = 0;
int PAUSED_STATE = 1;
int STOPPED_STATE = 2;

FlutterMethodChannel* _flautoChannel;
//BOOL includeAPFeatures = false;
Flauto* flautoModule; // Singleton

//+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar fluttterSoundModule: (FlutterSoundPlugin*)fluttterModule {
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flauto"
            binaryMessenger:[registrar messenger]];
  Flauto* instance = [[Flauto alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  _flautoChannel = channel;
}

extern void flautoreg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [Flauto registerWithRegistrar: registrar];
}

-(FlutterMethodChannel*) getChannel {
  return _flautoChannel;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
   if ([@"startPlayerFromTrack" isEqualToString:call.method]) {
            NSDictionary* trackDict = (NSDictionary*) call.arguments[@"track"];
            track = [[Track alloc] initFromDictionary:trackDict];
           
           BOOL canSkipForward = [call.arguments[@"canSkipForward"] boolValue];
           BOOL canSkipBackward = [call.arguments[@"canSkipBackward"] boolValue];
           [self startPlayer:canSkipForward canSkipBackward:canSkipBackward result:result];
  } else if ([@"stopPlayer" isEqualToString:call.method]) {
         [super stopPlayer];
         result(@"stop play");
  } else if ([@"initializeMediaPlayer" isEqualToString:call.method]) {
         //BOOL includeAudioPlayerFeatures = [call.arguments[@"includeAudioPlayerFeatures"] boolValue];
         [self initializeMediaPlayer: result:result];
  } else if ([@"releaseMediaPlayer" isEqualToString:call.method]) {
         [self releaseMediaPlayer:result];
  } else if ([@"pausePlayer" isEqualToString:call.method]) {
         [self pausePlayer:result];
  } else {
         [super handleMethodCall: call  result: result];
  }
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
        
        // Able to play in silent mode
        if (setCategoryDone == NOT_SET) {
                [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: nil];
                 setCategoryDone = FOR_PLAYING;
        }
        
        // Able to play in background
         if (setActiveDone == NOT_SET) {
                 [[AVAudioSession sharedInstance] setActive: YES error: nil];
                 setActiveDone = FOR_PLAYING;
         }


        
        // Check whether the file path poits to a remote or local file
        if (isRemote) {
            NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                                  dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                      // NSData *data = [NSData dataWithContentsOfURL:audioFileURL];
                                                      
                                                      // The file to play has been downloaded, then initialize the audio player
                                                      // and start playing.
                                                      
                                                      // We must create a new Audio Player instance to be able to play a different Url
                                                      audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
                                                      audioPlayer.delegate = self;
                                                      
                                                      // Able to play in silent mode
                                                      //[[AVAudioSession sharedInstance]
                                                       //setCategory: AVAudioSessionCategoryPlayback
                                                       //error: nil];
                                                      // Able to play in background
                                                      //[[AVAudioSession sharedInstance] setActive: YES error: nil];
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                                                      });
                                                      
                                                      [audioPlayer play];
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
            //[[AVAudioSession sharedInstance]
             //setCategory: AVAudioSessionCategoryPlayback
             //error: nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            });

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
        //[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        });
        [audioPlayer play];
        [self startTimer];
        result(@"Playing from buffer");
    }
    
    isPlaying = true;
    NSNumber *playingState = [NSNumber numberWithInt:PLAYING_STATE];
    [ [self getChannel] invokeMethod:@"updatePlaybackState" arguments:playingState];
    
    // Display the notification with the media controls
      [self setupRemoteCommandCenter:true canSkipForward:canSkipForward   canSkipBackward:canSkipBackward result:result];
      [self setupNowPlaying:nil];
}

// Give the system information about what the audio player
// is currently playing. Takes in the image to display in the
// notification to control the media playback.
- (void)setupNowPlaying:(MPMediaItemArtwork*)albumArt{
    // Initialize the MPNowPlayingInfoCenter
    
    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    // The caller specify an asset to be used.
    // Probably good in the future to allow the caller to specify the image itself, and not a resource.
    if (albumArt == nil)
    {
            if ([track.albumArt class] != [NSNull class])
            {
                UIImage* artworkImage = [UIImage imageNamed: track.albumArt];
                MPMediaItemArtwork *albumArt2 = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                [songInfo setObject:albumArt2 forKey: MPMediaItemPropertyArtwork];
            }
    } else
    {
            [songInfo setObject:albumArt forKey: MPMediaItemPropertyArtwork];
    }
    
    NSNumber *progress = [NSNumber numberWithDouble: audioPlayer.currentTime];
    NSNumber *duration = [NSNumber numberWithDouble: audioPlayer.duration];
    
    [songInfo setObject:track.title forKey:MPMediaItemPropertyTitle];
    [songInfo setObject:track.author forKey:MPMediaItemPropertyArtist];
    [songInfo setObject:progress forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [songInfo setObject:duration forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:[NSNumber numberWithDouble:(isPlaying ? 1.0f : 0.0f)] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    [playingInfoCenter setNowPlayingInfo:songInfo];
}


- (void)cleanTarget:(BOOL)canPause canSkipForward:(BOOL)canSkipForward  canSkipBackward:(BOOL)canSkipBackward
{
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
          MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
          [commandCenter.togglePlayPauseCommand setEnabled:canPause];
          [commandCenter.nextTrackCommand setEnabled:canSkipForward];
          [commandCenter.previousTrackCommand setEnabled:canSkipBackward];

          if (pauseTarget != nil)
          {
              [commandCenter.togglePlayPauseCommand removeTarget: pauseTarget action: nil];
              pauseTarget = nil;
          }
          if (forwardTarget != nil)
          {
              [commandCenter.nextTrackCommand removeTarget: forwardTarget action: nil];
              forwardTarget = nil;
          }
          
          if (backwardTarget != nil)
          {
              [commandCenter.previousTrackCommand removeTarget: backwardTarget action: nil];
              backwardTarget = nil;
          }
          
          if (canPause)
          {
                  pauseTarget = [commandCenter.togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                       printf("Pause handler called by ios\n");
                       FlutterResult result;
                       if(isPlaying) {
                            //!!!![self pause];
                            [[self getChannel] invokeMethod:@"pause" arguments:nil];
                        } else {
                            //!!!![self resume];
                            [[self getChannel] invokeMethod:@"resume" arguments:nil];
                        }
                  
                           return MPRemoteCommandHandlerStatusSuccess;
                          }];

          }
                     
             if (canSkipForward)
                {
                        forwardTarget = [commandCenter.nextTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                            [[self getChannel] invokeMethod:@"skipForward" arguments:nil];
                            // [[MediaController sharedInstance] fastForward];    // forward to next track.
                            printf("Next handler called by ios\n");
                            return MPRemoteCommandHandlerStatusSuccess;
                        }];
                }
                
                if (canSkipBackward)
                {
                        backwardTarget = [commandCenter.previousTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                            [[self getChannel] invokeMethod:@"skipBackward" arguments:nil];
                            // [[MediaController sharedInstance] rewind];    // back to previous track.
                            printf("Previous handler called by ios\n");
                            return MPRemoteCommandHandlerStatusSuccess;
                        }];
                }
}


- (void)stopPlayer {
  [self stopTimer];
  if (audioPlayer) {
    [audioPlayer stop];
    //[LARPOUX]audioPlayer = nil;
  }
  [self cleanTarget:false canSkipForward:false canSkipBackward:false];
  if ( (setActiveDone != BY_USER) && (setActiveDone != NOT_SET) ) {
      [[AVAudioSession sharedInstance] setActive: NO error: nil];
      setActiveDone = NOT_SET;
  }
}



// Give the system information about what to do when the notification
// control buttons are pressed.
- (void)setupRemoteCommandCenter:(BOOL)canPause canSkipForward:(BOOL)canSkipForward canSkipBackward:(BOOL)canSkipBackward result: (FlutterResult)result {
    
     
    [self cleanTarget:canPause canSkipForward:canSkipForward canSkipBackward:canSkipBackward];
    /*
         if(isPlaying) {
             [self pausePlayer: result];
             [[self getChannel] invokeMethod:@"pause" arguments:nil];
         } else {
             [self resumePlayer: result];
             [[self getChannel] invokeMethod:@"resume" arguments:nil];
         }
         
         // [[MediaController sharedInstance] playOrPauseMusic];    // Begin playing the current track.
         */
 

   }


-(void)initializeMediaPlayer: result: (FlutterResult)result {
    // Set whether we have to include the audio player features
    //includeAPFeatures = includeAudioPlayerFeatures;
     // No further initialization is needed for the iOS audio player, then exit
    // the method.
    result(@"The player had already been initialized.");
}

- (void)releaseMediaPlayer:(FlutterResult)result {
    // The code used to release all the media player resources is the same of the one needed
    // to stop the media playback. Then, use that one.
    // [self stopRecorder:result];
    [self stopPlayer];
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    if (pauseTarget != nil)
    {
        [commandCenter.togglePlayPauseCommand removeTarget: pauseTarget action: nil];
        pauseTarget = nil;
    }
    if (forwardTarget != nil)
    {
        [commandCenter.nextTrackCommand removeTarget: forwardTarget action: nil];
        forwardTarget = nil;
    }
    
    if (backwardTarget != nil)
    {
        [commandCenter.previousTrackCommand removeTarget: backwardTarget action: nil];
        backwardTarget = nil;
    }

    result(@"The player has been successfully released");

}

// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
static NSString* GetDirectoryOfType_FlutterSound(NSSearchPathDirectory dir) {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
    return [paths.firstObject stringByAppendingString:@"/"];
}

@end
