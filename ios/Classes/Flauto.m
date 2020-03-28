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

FlutterMethodChannel* _flautoChannel;

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
           BOOL canPause  = [call.arguments[@"canPause"] boolValue];
           BOOL canSkipForward = [call.arguments[@"canSkipForward"] boolValue];
           BOOL canSkipBackward = [call.arguments[@"canSkipBackward"] boolValue];
           [self startPlayerFromTrack: canPause canSkipForward:canSkipForward canSkipBackward:canSkipBackward result:result];
  } else if ([@"initializeMediaPlayer" isEqualToString:call.method]) {
         [self initializeMediaPlayer: result:result];
  } else if ([@"releaseMediaPlayer" isEqualToString:call.method]) {
         [self releaseMediaPlayer:result];
  } else {
         [super handleMethodCall: call  result: result];
  }
}


- (void)startPlayerFromTrack:(BOOL)canPause canSkipForward: (BOOL)canSkipForward canSkipBackward: (BOOL)canSkipBackward result: (FlutterResult)result {
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
            // This file name is not good. Perhaps the codec is not AAC. !
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

        isPaused = false;

        // Check whether the file path points to a remote or local file
        if (isRemote) {
            NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                                  dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                      // The file to play has been downloaded, then initialize the audio player
                                                      // and start playing.

                                                      // We must create a new Audio Player instance to be able to play a different Url
                                                      audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
                                                      audioPlayer.delegate = self;
                                                      
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                                                      });

                                                      [audioPlayer play];
                                                   }];

            [downloadTask resume];
            [self startTimer];
             NSString *filePath = self->audioFileURL.absoluteString;
             result(filePath);

        } else {
            // Initialize the audio player with the file that the given path points to,
            // and start playing.

            // if (!audioPlayer) { // Fix sound distoring when playing recorded audio again.
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
            audioPlayer.delegate = self;
            // }

            // Able to play in silent mode
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        });
        [audioPlayer play];
        [self startTimer];
        result(@"Playing from buffer");
    }
    //[ [self getChannel] invokeMethod:@"updatePlaybackState" arguments:playingState];

    // Display the notification with the media controls
      [self setupRemoteCommandCenter:canPause canSkipForward:canSkipForward   canSkipBackward:canSkipBackward result:result];
      [self setupNowPlaying];

}

// Give the system information about what the audio player
// is currently playing. Takes in the image to display in the
// notification to control the media playback.
- (void)setupNowPlaying
{
    // Initialize the MPNowPlayingInfoCenter

    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    // The caller specify an asset to be used.
    // Probably good in the future to allow the caller to specify the image itself, and not a resource.
    if ((track.albumArtUrl != nil) && ([track.albumArtUrl class] != [NSNull class])   )
    {
        // Retrieve the album art for the
        // current track .
            NSURL *url = [NSURL URLWithString:self->track.albumArtUrl];
            UIImage *artworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            if(artworkImage)
            {
                MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
            }
    } else
    if ((track.albumArtAsset) && ([track.albumArtAsset class] != [NSNull class])   )
    {
            UIImage* artworkImage = [UIImage imageNamed: track.albumArtAsset];
            if (artworkImage != nil) {
                MPMediaItemArtwork* albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                [songInfo setObject:albumArt forKey: MPMediaItemPropertyArtwork];
            }
    }

    NSNumber *progress = [NSNumber numberWithDouble: audioPlayer.currentTime];
    NSNumber *duration = [NSNumber numberWithDouble: audioPlayer.duration];

    [songInfo setObject:track.title forKey:MPMediaItemPropertyTitle];
    [songInfo setObject:track.author forKey:MPMediaItemPropertyArtist];
    [songInfo setObject:progress forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [songInfo setObject:duration forKey:MPMediaItemPropertyPlaybackDuration];
    bool b = [audioPlayer isPlaying];
    [songInfo setObject:[NSNumber numberWithDouble:(b ? 1.0f : 0.0f)] forKey:MPNowPlayingInfoPropertyPlaybackRate];

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
          [commandCenter.togglePlayPauseCommand setEnabled: true]; // If the caller does not want to control pause button, we will use our default action
          [commandCenter.nextTrackCommand setEnabled:canSkipForward];
          [commandCenter.previousTrackCommand setEnabled:canSkipBackward];

          {
                pauseTarget = [commandCenter.togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                       FlutterResult result;
                       bool b = [audioPlayer isPlaying];
                       // If the caller wants to control the pause button, just call him
                       if (b)
                       {
                            if (canPause)
                                [[self getChannel] invokeMethod:@"pause" arguments:nil];
                            else
                                [self pause];
                        } else
                        {
                            if (canPause)
                            {
                                if (isPaused)
                                        [[self getChannel] invokeMethod:@"resume" arguments:nil];
                                else
                                        [[self getChannel] invokeMethod:@"pause" arguments:nil]; // Patch : ios, maybe a pause during the timer instruction
                                        
                            } else
                                [self resume];
                        }
                        return MPRemoteCommandHandlerStatusSuccess;
                }];
          }

                if (canSkipForward)
                {
                        forwardTarget = [commandCenter.nextTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                        {
                            [[self getChannel] invokeMethod:@"skipForward" arguments:nil];
                            // [[MediaController sharedInstance] fastForward];    // forward to next track.
                            return MPRemoteCommandHandlerStatusSuccess;
                        }];
                }

                if (canSkipBackward)
                {
                        backwardTarget = [commandCenter.previousTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                        {
                            [[self getChannel] invokeMethod:@"skipBackward" arguments:nil];
                            // [[MediaController sharedInstance] rewind];    // back to previous track.
                            return MPRemoteCommandHandlerStatusSuccess;
                        }];
                }
}


- (void)stopPlayer
{
          [self stopTimer];
          isPaused = false;
          if (audioPlayer)
          {
                [audioPlayer stop];
                //audioPlayer = nil;
          }
          // ????  [self cleanTarget:false canSkipForward:false canSkipBackward:false];
          if ( (setActiveDone != BY_USER) && (setActiveDone != NOT_SET) )
          {
                [self cleanTarget:false canSkipForward:false canSkipBackward:false]; // ???
                [[AVAudioSession sharedInstance] setActive: NO error: nil];
                setActiveDone = NOT_SET;
          }
}



// Give the system information about what to do when the notification
// control buttons are pressed.
- (void)setupRemoteCommandCenter:(BOOL)canPause canSkipForward:(BOOL)canSkipForward canSkipBackward:(BOOL)canSkipBackward result: (FlutterResult)result {
    [self cleanTarget:canPause canSkipForward:canSkipForward canSkipBackward:canSkipBackward];
   }


-(void)initializeMediaPlayer: result: (FlutterResult)result {
    // Set whether we have to include the audio player features
    //includeAPFeatures = includeAudioPlayerFeatures;
     // No further initialization is needed for the iOS audio player, then exit
    // the method.
    result(@"The player has been initialized.");
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
