/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */




#import "TrackPlayer.h"
#import "Track.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>




//---------------------------------------------------------------------------------------------

@implementation TrackPlayer
{
       NSURL *audioFileURL;
       Track *track;
       id forwardTarget;
       id backwardTarget;
       id pauseTarget;
       id togglePlayPauseTarget;
       id stopTarget;
       id playTarget;
       MPMediaItemArtwork* albumArt ;
       BOOL defaultPauseResume;
       BOOL removeUIWhenStopped;
}
 
- (TrackPlayer*)init: (FlutterMethodCall*)call
{
        return [super init: call];
}


- (void)releaseFlautoPlayer:(FlutterMethodCall*)call result:(FlutterResult)result
{
        NSLog(@"IOS:--> releaseFlautoPlayer");
        [self stopPlayer];
        [self cleanNowPlaying];
        removeUIWhenStopped = true;
        [self cleanTarget];
        [super releaseFlautoPlayer: call result: result];
        result([NSNull null]);;
        NSLog(@"IOS:<-- releaseFlautoPlayer");
}


- (void)startPlayerFromTrack:(FlutterMethodCall*)call result: (FlutterResult)result
{
         NSLog(@"IOS:--> startPlayerFromTrack");
         bool r = FALSE;
         NSDictionary* trackDict = (NSDictionary*) call.arguments[@"track"];
         track = [[Track alloc] initFromDictionary:trackDict];
         BOOL canPause  = [call.arguments[@"canPause"] boolValue];
         BOOL canSkipForward = [call.arguments[@"canSkipForward"] boolValue];
         BOOL canSkipBackward = [call.arguments[@"canSkipBackward"] boolValue];
         NSNumber* progress = (NSNumber*)call.arguments[@"progress"];
         NSNumber* duration = (NSNumber*)call.arguments[@"duration"];
         removeUIWhenStopped  = [call.arguments[@"removeUIWhenStopped"] boolValue];


        defaultPauseResume  = [call.arguments[@"defaultPauseResume"] boolValue];

        if(!track)
        {
                result([FlutterError errorWithCode:@"UNAVAILABLE"
                                   message:@"The track passed to startPlayer is not valid."
                                   details:nil]);
                return;
        }
        [self stopPlayer]; // to start a fresh new playback

        // Check whether the audio file is stored as a path to a file or a buffer
        if([track isUsingPath])
        {
                // The audio file is stored as a path to a file

                NSString *path = track.path;

                bool isRemote = false;
                // Check whether a path was given
                //if ([path class] == [NSNull class])
                //{
                        // No path was given, get the path to a default sound
                        //audioFileURL = [NSURL fileURLWithPath:[GetDirectoryOfType_FlutterSound(NSCachesDirectory) stringByAppendingString:@"sound.aac"]];
                // This file name is not good. Perhaps the codec is not AAC. !
                //} else
                {
                        // A path was given, then create a NSURL with it
                        NSURL *remoteUrl = [NSURL URLWithString:path];

                        // Check whether the URL points to a local or remote file
                        if(remoteUrl && remoteUrl.scheme && remoteUrl.host)
                        {
                                audioFileURL = remoteUrl;
                                isRemote = true;
                        } else
                        {
                                audioFileURL = [NSURL URLWithString:path];
                        }
                }

                 //isPaused = false;
                if (!hasFocus) // We always acquire the Audio Focus (It could have been released by another session)
                {
                        hasFocus = TRUE;
                        r = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
                }



                // Check whether the file path points to a remote or local file
                if (isRemote)
                {
                        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                                  dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                      // The file to play has been downloaded, then initialize the audio player
                                                      // and start playing.

                                                      // We must create a new Audio Player instance to be able to play a different Url
                                                      audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
                                                      audioPlayer.delegate = self;

                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          NSLog(@"IOS: ^beginReceivingRemoteControlEvents");
                                                          [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                                                      });

                                                      [audioPlayer play];
                                                   }];
                        r = true; // ??? not sure
                        [downloadTask resume];
                        //[self startTimer];
                } else
                {
                        // Initialize the audio player with the file that the given path points to,
                        // and start playing.

                        // if (!audioPlayer) { // Fix sound distoring when playing recorded audio again.
                        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
                        audioPlayer.delegate = self;
                        // }

                        // Able to play in silent mode
                        dispatch_async(dispatch_get_main_queue(),
                        ^{
                                NSLog(@"^beginReceivingRemoteControlEvents");
                                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        });

                        r = [audioPlayer play];
                        if (![audioPlayer isPlaying])
                                NSLog(@"IOS: AudioPlayer failed to play");
                        else
                                NSLog(@"IOS: !Play");
                        //[self startTimer];
                }
        } else
        {
        // The audio file is stored as a buffer
                FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*) track.dataBuffer;
                NSData* bufferData = [dataBuffer data];
                //if (audioPlayer != nil)
                        //[audioPlayer stop];
                audioPlayer = [[AVAudioPlayer alloc] initWithData: bufferData error: nil];
                audioPlayer.delegate = self;
                dispatch_async(dispatch_get_main_queue(),
                ^{
                        NSLog(@"^beginReceivingRemoteControlEvents");
                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                });
                r = [audioPlayer play];
                if (![audioPlayer isPlaying])
                        NSLog(@"IOS: AudioPlayer failed to play");
                else
                        NSLog(@"IOS: !Play");
                //[self startTimer];
        }
         if (r)
         {
                [self startTimer];
                // Display the notification with the media controls
                //[self cleanTarget]; // Done by setupRemoteCommandCenter()
                [self setupRemoteCommandCenter:canPause canSkipForward:canSkipForward   canSkipBackward:canSkipBackward ];
                
                if ( (progress == nil) || (progress.class == NSNull.class) )
                        progress = [NSNumber numberWithDouble: audioPlayer.currentTime];
                else
                        progress = [NSNumber numberWithDouble: [progress doubleValue] / 1000.0];
                if ( (duration == nil) || (duration.class == NSNull.class) )
                        duration = [NSNumber numberWithDouble: audioPlayer.duration];
                else
                        duration = [NSNumber numberWithDouble: [duration doubleValue] / 1000.0];
                [self setupNowPlaying: progress duration: duration];
                



                long duration = (long)(audioPlayer.duration * 1000);
                int d = (int)duration;
                NSNumber* nd = [NSNumber numberWithInt: d];
                [self invokeMethod:@"startPlayerCompleted" numberArg: nd ];


                result([self getPlayerStatus]);
         }
        else
             result([FlutterError errorWithCode:@"FAILED"
                                   message:@"startPlayerFromTrack()"
                                   details:nil]);
         NSLog(@"IOS:<-- startPlayerFromTrack");
}


- (void)updateProgress:(NSTimer*) atimer
{
        [super updateProgress: atimer];
}




// Give the system information about what the audio player
// is currently playing. Takes in the image to display in the
// notification to control the media playback.
- (void)setupNowPlaying: (NSNumber*) progress duration: (NSNumber*)duration
{
        NSLog(@"IOS:--> setupNowPlaying");

        // Initialize the MPNowPlayingInfoCenter

         albumArt = nil;
        // The caller specify an asset to be used.
        // Probably good in the future to allow the caller to specify the image itself, and not a resource.
        if ((track.albumArtUrl != nil) && ([track.albumArtUrl class] != [NSNull class])   )         // The albumArt is accessed in a URL
        {
                // Retrieve the album art for the
                // current track .
                NSURL* url = [NSURL URLWithString:self->track.albumArtUrl];
                UIImage* artworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                if(artworkImage)
                {
                        albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                 }
        } else
        if ((track.albumArtAsset) && ([track.albumArtAsset class] != [NSNull class])   )        // The albumArt is an Asset
        {
                UIImage* artworkImage = [UIImage imageNamed: track.albumArtAsset];
                if (artworkImage != nil)
                {
                        albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];

                }
        } else
        if ((track.albumArtFile) && ([track.albumArtFile class] != [NSNull class])   )          //  The AlbumArt is a File
        {
                UIImage* artworkImage = [UIImage imageWithContentsOfFile: track.albumArtFile];
                if (artworkImage != nil)
                {
                        albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                }
        } else // Nothing specified. We try to use the App Icon
        {
                UIImage* artworkImage = [UIImage imageNamed: @"AppIcon"];
                if (artworkImage != nil)
                {
                        albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                }
        }
        //NSNumber* progress = [NSNumber numberWithDouble: audioPlayer.currentTime];
        //NSNumber* duration = [NSNumber numberWithDouble: audioPlayer.duration];
        [self setUIProgressBar: progress duration: duration];
        NSLog(@"IOS:<-- setupNowPlaying");

}


- (void)cleanTarget
{
          NSLog(@"IOS:--> cleanTarget");
          MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

          if (togglePlayPauseTarget != nil)
          {
                [commandCenter.togglePlayPauseCommand removeTarget: togglePlayPauseTarget action: nil];
                pauseTarget = nil;
          }

          if (pauseTarget != nil)
          {
                [commandCenter.pauseCommand removeTarget: pauseTarget action: nil];
                pauseTarget = nil;
          }

          if (playTarget != nil)
          {
                [commandCenter.playCommand removeTarget: playTarget action: nil];
                pauseTarget = nil;
          }

          if (stopTarget != nil)
          {
                [commandCenter.stopCommand removeTarget: stopTarget action: nil];
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
          
      
          //albumArt = nil;
          NSLog(@"IOS:<-- cleanTarget");
 }


- (void)stopPlayer
{
          NSLog(@"IOS:--> stopPlayer");
          [self stopTimer];
          //isPaused = false;
          if (audioPlayer)
          {
                NSLog(@"IOS: !stopPlayer");
                [audioPlayer stop];
                audioPlayer = nil;
          }
          //[self cleanTarget];
          if (removeUIWhenStopped)
          {
                [self cleanTarget];
                MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
                [playingInfoCenter setNowPlayingInfo: nil];
                playingInfoCenter.nowPlayingInfo = nil;
          }
          NSLog(@"IOS:<-- stopPlayer");
}



// Give the system information about what to do when the notification
// control buttons are pressed.
- (void)setupRemoteCommandCenter:(BOOL)canPause canSkipForward:(BOOL)canSkipForward canSkipBackward:(BOOL)canSkipBackward
{
        NSLog(@"IOS:--> setupRemoteCommandCenter");
        [self cleanTarget];
        MPRemoteCommandCenter* commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        if (canPause)
        {

                togglePlayPauseTarget = [commandCenter.togglePlayPauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        NSLog(@"IOS: toggleTarget\n");
                        dispatch_async(dispatch_get_main_queue(), ^{
 
 
                                bool b = [audioPlayer isPlaying];
                                // If the caller wants to control the pause button, just call him
                                if (b)
                                {
                                        if (defaultPauseResume)
                                                [self pause];
                                        [self invokeMethod:@"pause" numberArg: [self getPlayerStatus] ];
                                } else
                                {
                                        if (defaultPauseResume)
                                                [self resume];
                                        [self invokeMethod:@"pause" numberArg: [self getPlayerStatus]];
                                }
                        });
                        return MPRemoteCommandHandlerStatusSuccess;
                }];

                pauseTarget = [commandCenter.pauseCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        NSLog(@"IOS: pauseTarget\n");
                        dispatch_async(dispatch_get_main_queue(), ^{
                                bool b = [audioPlayer isPlaying];
                                // If the caller wants to control the pause button, just call him
                                if (b)
                                {
                                        if (defaultPauseResume)
                                                [self pause];
                                        [self invokeMethod:@"pause" numberArg: [self getPlayerStatus]];
                                }
                        });
                        return MPRemoteCommandHandlerStatusSuccess;
                 }];

                stopTarget = [commandCenter.stopCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        NSLog(@"IOS: stopTarget\n");
                        return MPRemoteCommandHandlerStatusSuccess;
                }];


                playTarget = [commandCenter.playCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        NSLog(@"IOS: playTarget\n");
                        dispatch_async(dispatch_get_main_queue(), ^{
                                bool b = [audioPlayer isPlaying];
                                // If the caller wants to control the pause button, just call him
                                if (!b)
                                {
                                        if (defaultPauseResume)
                                                [self resume];
                                        [self invokeMethod:@"pause" numberArg: [self getPlayerStatus]];
                                }
                        });
                                
                        return MPRemoteCommandHandlerStatusSuccess;
                }];
        }

        commandCenter.togglePlayPauseCommand.enabled = canPause;
        commandCenter.playCommand.enabled = canPause;
        commandCenter.stopCommand.enabled = canPause;
        commandCenter.pauseCommand.enabled = canPause;

        [commandCenter.togglePlayPauseCommand setEnabled: canPause]; // If the caller does not want to control pause button, we will use our default action
        [commandCenter.playCommand setEnabled: canPause]; // If the caller does not want to control pause button, we will use our default action
        [commandCenter.stopCommand setEnabled: canPause]; // If the caller does not want to control pause button, we will use our default action
        [commandCenter.pauseCommand setEnabled: canPause]; // If the caller does not want to control pause button, we will use our default action

        [commandCenter.nextTrackCommand setEnabled:canSkipForward];
        [commandCenter.previousTrackCommand setEnabled:canSkipBackward];


        if (canSkipForward)
        {
                forwardTarget = [commandCenter.nextTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        [self invokeMethod:@"skipForward" numberArg: [self getPlayerStatus]];
                        // [[MediaController sharedInstance] fastForward];    // forward to next track.
                        return MPRemoteCommandHandlerStatusSuccess;
                }];
        }

        if (canSkipBackward)
        {
                backwardTarget = [commandCenter.previousTrackCommand addTargetWithHandler: ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        [self invokeMethod:@"skipBackward" numberArg: [self getPlayerStatus]];
                        // [[MediaController sharedInstance] rewind];    // back to previous track.
                        return MPRemoteCommandHandlerStatusSuccess;
                }];
        }
       NSLog(@"IOS:<-- setupRemoteCommandCenter");
 }


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
static NSString* GetDirectoryOfType_FlutterSound(NSSearchPathDirectory dir)
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void)setUIProgressBar:(NSNumber*)progress duration:(NSNumber*)duration
{
        NSLog(@"IOS:--> setUIProgressBar");
        NSMutableDictionary* songInfo = [[NSMutableDictionary alloc] init];

        if ( (progress != nil) && ([progress class] != [NSNull class]) && (duration != nil) && ([duration class] != [NSNull class]))
        {
                NSLog(@"IOS: setUIProgressBar Progress: %@ s.", progress);
                NSLog(@"IOS: setUIProgressBar Duration: %@ s.", duration);
                [songInfo setObject: progress forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime];
                [songInfo setObject: duration forKey: MPMediaItemPropertyPlaybackDuration];
        }

        if (albumArt != nil)
        {
                       [songInfo setObject:albumArt forKey: MPMediaItemPropertyArtwork];
        }

        if (track != nil)
        {
                [songInfo setObject: track.title forKey: MPMediaItemPropertyTitle];
                [songInfo setObject: track.author forKey: MPMediaItemPropertyArtist];
        }
        bool b = [audioPlayer isPlaying];
        [songInfo setObject:[NSNumber numberWithDouble:(b ? 1.0f : 0.0f)] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        
        //[songInfo setObject: @"toto" forKey: MPNowPlayingInfoCollectionIdentifier];
        //[songInfo setObject: @"titi" forKey: MPNowPlayingInfoPropertyChapterCount];
        //[songInfo setObject: @"tutu" forKey: MPNowPlayingInfoPropertyChapterNumber];

        MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
        [playingInfoCenter setNowPlayingInfo: songInfo];
        NSLog(@"IOS:<-- setUIProgressBar");

}

- (void)updateLockScreenProgression
{
        NSLog(@"IOS:--> updateLockScreenProgression");
        NSNumber* progress = [NSNumber numberWithDouble: audioPlayer.currentTime/1000.0];
        NSNumber* duration = [NSNumber numberWithDouble: audioPlayer.duration/1000.0];
        [self setUIProgressBar: progress duration: duration];
        NSLog(@"IOS:<-- updateLockScreenProgression");
}




- (void)setUIProgressBar:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> setUIProgressBar");
        NSNumber* x = (NSNumber*)call.arguments[@"progress"];
        NSNumber* y = (NSNumber*)call.arguments[@"duration"];
        double progress = [ x doubleValue];
        double duration = [ y doubleValue];
        NSNumber* p = [NSNumber numberWithDouble: progress/1000.0];
        NSNumber* d = [NSNumber numberWithDouble: duration/1000.0];
        [self setUIProgressBar: p duration: d];
        result([self getPlayerStatus]);
        NSLog(@"IOS:<-- setUIProgressBar");
}

- (void)cleanNowPlaying
{
                MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
                [playingInfoCenter setNowPlayingInfo: nil];
                playingInfoCenter.nowPlayingInfo = nil;

}


- (void)nowPlaying:(FlutterMethodCall*)call result: (FlutterResult)result
{
         NSLog(@"IOS:--> nowPlaying");
         bool r = FALSE;
         track = nil;
         NSDictionary* trackDict = (NSDictionary*) call.arguments[@"track"];
         if ((trackDict != nil) && ([trackDict class] != [NSNull class]) )
                track = [[Track alloc] initFromDictionary:trackDict];

        BOOL canPause  = [call.arguments[@"canPause"] boolValue];
        BOOL canSkipForward = [call.arguments[@"canSkipForward"] boolValue];
        BOOL canSkipBackward = [call.arguments[@"canSkipBackward"] boolValue];
        defaultPauseResume  = [call.arguments[@"defaultPauseResume"] boolValue];

        [self setupRemoteCommandCenter:canPause canSkipForward:canSkipForward   canSkipBackward:canSkipBackward ];
        if ( !track  )
        {
                [self cleanNowPlaying];
                result([self getPlayerStatus]);
                return;
        }

        NSNumber* progress = (NSNumber*)call.arguments[@"progress"];
        NSNumber* duration = (NSNumber*)call.arguments[@"duration"];
        if ( (progress != nil) && ([progress class] != [NSNull class]))
        {
                double x = [ progress doubleValue];
                progress = [NSNumber numberWithFloat: x/1000.0];
        }
        if ( (duration != nil) && ([duration class] != [NSNull class]))
        {
                double y = [ duration doubleValue];
                duration = [NSNumber numberWithFloat: y/1000.0];
        }


        [self setupNowPlaying: progress duration: duration];
        result([self getPlayerStatus]);
        NSLog(@"IOS:<-- nowPlaying");

}


- (void)seekToPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{

        NSLog(@"IOS:--> seekToPlayer");
        [super seekToPlayer: call result:result];
        [self updateLockScreenProgression];
        NSLog(@"IOS:<-- seekToPlayer");
  }

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
        NSLog(@"IOS:--> audioPlayerDidFinishPlaying");
        //[self cleanTarget];
        if (removeUIWhenStopped)
        {
                [self cleanTarget];
                MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
                [playingInfoCenter setNowPlayingInfo: nil];
                playingInfoCenter.nowPlayingInfo = nil;
        }

        [super audioPlayerDidFinishPlaying: player successfully: flag];
        NSLog(@"IOS:<-- audioPlayerDidFinishPlaying");
}

- (bool)resume
{
        NSLog(@"IOS:--> resume");
        bool b = [super resume];
        // TEMPORARY // TODO // [self updateLockScreenProgression];
        NSLog(@"IOS:<-- resume");
        return b;
}
@end
