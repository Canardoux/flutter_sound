/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of the Tau project.
 *
 * Tau is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Tau is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the Tau project.  If not, see <https://www.gnu.org/licenses/>.
 */


#import "FlautoTrackPlayer.h"
#import "FlautoTrack.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>




//---------------------------------------------------------------------------------------------

@implementation FlautoTrackPlayer
{
       NSURL* audioFileURL;
       FlautoTrack* m_track;
       id forwardTarget;
       id backwardTarget;
       id pauseTarget;
       id togglePlayPauseTarget;
       id stopTarget;
       id playTarget;
       MPMediaItemArtwork* albumArt ;
       BOOL m_defaultPauseResume;
       BOOL m_removeUIWhenStopped;
}
- (FlautoTrackPlayer*)init: (NSObject<FlautoPlayerCallback>*) callback;
{
        return [super init: callback];
}


- (void)releaseFlautoPlayer;
{
        NSLog(@"IOS:--> releaseFlautoPlayer");
        [self stopPlayer];
        [self cleanNowPlaying];
        m_removeUIWhenStopped = true;
        [self cleanTarget];
        [super releaseFlautoPlayer];
        NSLog(@"IOS:<-- releaseFlautoPlayer");
}

- (AVAudioPlayer*)getPlayer
{
        return [(AudioPlayerFlauto*)m_playerEngine  getAudioPlayer];

}

- (void)setPlayer:(AVAudioPlayer*) theAudioPlayer
{
        [(AudioPlayerFlauto*)m_playerEngine  setAudioPlayer: theAudioPlayer];
}




- (NSString*) getpath:  (NSString*)path
{
         if ((path == nil)|| ([path class] == [[NSNull null] class]))
                return nil;
        if (![path containsString: @"/"]) // Temporary file
        {
                path = [NSTemporaryDirectory() stringByAppendingPathComponent: path];
        }
        return path;
}

- (NSString*) getUrl: (NSString*)path
{
         if ((path == nil)|| ([path class] == [[NSNull null] class]))
                return nil;
        path = [self getpath: path];
        NSURL* url = [NSURL URLWithString: path];
        return [url absoluteString];
}



- (bool)startPlayerFromTrack: (FlautoTrack*)track canPause: (bool)canPause canSkipForward: (bool)canSkipForward canSkipBackward: (bool)canSkipBackward
        progress: (NSNumber*)progress duration: (NSNumber*)duration removeUIWhenStopped: (bool)removeUIWhenStopped defaultPauseResume: (bool)defaultPauseResume;
{
         NSLog(@"IOS:--> startPlayerFromTrack");
         bool r = FALSE;

        if(!track)
        {
                return false;
        }
        m_track = track;
        m_removeUIWhenStopped = removeUIWhenStopped;
        m_defaultPauseResume = defaultPauseResume;
        //[self stopPlayer]; // to start a fresh new playback
        [self stop];
        m_playerEngine = [[AudioPlayerFlauto alloc]init: self];

        // Check whether the audio file is stored as a path to a file or a buffer
        if([track isUsingPath])
        {
                // The audio file is stored as a path to a file

                NSString *path = track.path;

                bool isRemote = false;
                path = [self getpath: path];

                // A path was given, then create a NSURL with it
                NSURL *remoteUrl = [NSURL URLWithString:path];

                // Check whether the URL points to a local or remote file
                if(remoteUrl && remoteUrl.scheme && remoteUrl.host)
                {
                        audioFileURL = remoteUrl;
                        isRemote = true;
                } else
                {
                        path = [self getpath: path];

                        audioFileURL = [NSURL URLWithString:path];
                }

                if (!hasFocus) //  (It could have been released by another session)
                {
                        hasFocus = TRUE;
                        r = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
                }



                // Check whether the file path points to a remote or local file
                if (isRemote)
                {
                        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                  dataTaskWithURL:audioFileURL completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error)
                                  {
                                        // The file to play has been downloaded, then initialize the audio player
                                        // and start playing.

                                        // We must create a new Audio Player instance to be able to play a different Url
                                        NSError* err = nil;
                                        [self setPlayer: [[AVAudioPlayer alloc] initWithData: data error: &err] ];
                                        if (err != nil)
                                        {
                                                //NSLog([err localizedDescription]);
                                                return;
                                        }
                                        [self getPlayer].delegate = self;

                                        dispatch_async(dispatch_get_main_queue(),
                                        ^{
                                                NSLog(@"IOS: ^beginReceivingRemoteControlEvents");
                                                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                                                [self setupRemoteCommandCenter: canPause canSkipForward: canSkipForward   canSkipBackward: canSkipBackward ];

                                        });

                                        [[self getPlayer] play];
                                        [self startTimer];
                                        //[self setupRemoteCommandCenter: canPause canSkipForward: canSkipForward   canSkipBackward: canSkipBackward ];
                                        NSNumber* _duration ;
                                        NSNumber* _progress ;
                                         if ( (progress == nil) || (progress.class == NSNull.class) )
                                                _progress = [NSNumber numberWithDouble: [self getPlayer].currentTime];
                                        else
                                                _progress = [NSNumber numberWithDouble: [progress doubleValue] / 1000.0];
                                        if ( (duration == nil) || (duration.class == NSNull.class) )
                                                _duration = [NSNumber numberWithDouble: [self getDuration] / 1000.0];
                                        else
                                                _duration = [NSNumber numberWithDouble: [duration doubleValue] / 1000.0];

                                        [self setupNowPlaying: _progress duration: _duration];
                                        long durationLong =  (long)([_duration doubleValue] * 1000.0) ;
                                        [ self ->m_callBack startPlayerCompleted: true duration: durationLong];

                                }];
                        r = true; // ??? not sure
                        [downloadTask resume];
                        //[self setUIProgressBar: progress duration: duration];

                        return true;
                } else
                {
                        // Initialize the audio player with the file that the given path points to,
                        // and start playing.
                        [self setPlayer: [[AVAudioPlayer alloc] initWithContentsOfURL: audioFileURL error:nil] ];
                        [self getPlayer].delegate = self;
                        // }

                        // Able to play in silent mode
                        dispatch_async(dispatch_get_main_queue(),
                        ^{
                                NSLog(@"^beginReceivingRemoteControlEvents");
                                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        });

                        r = [[self getPlayer] play];
                        if (![[self getPlayer] isPlaying])
                                NSLog(@"IOS: AudioPlayerFlauto failed to play");
                        else
                                NSLog(@"IOS: !Play");
                        //[self startTimer];
                }
        } else
        {
        // The audio file is stored as a buffer
                NSData* bufferData = track.dataBuffer;
                NSError* error;
                AVAudioPlayer* audioPlayer = [[AVAudioPlayer alloc] initWithData: bufferData error: &error];
                if (audioPlayer == nil)
                {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
                        //NSLog([error localizedDescription]);
#pragma clang diagnostic pop
                        return false;
                }
                [self setPlayer: audioPlayer ];
                [self getPlayer].delegate = self;
                dispatch_async(dispatch_get_main_queue(),
                ^{
                        NSLog(@"^beginReceivingRemoteControlEvents");
                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                });
                r = [[self getPlayer] play];
                if (![[self getPlayer] isPlaying])
                        NSLog(@"IOS: AudioPlayerFlauto failed to play");
                else
                        NSLog(@"IOS: !Play");
        }
        if (r)
        {
                [self startTimer];
                // Display the notification with the media controls
                [self setupRemoteCommandCenter: canPause canSkipForward: canSkipForward   canSkipBackward: canSkipBackward ];
                        if ( (progress == nil) || (progress.class == NSNull.class) )
                                progress = [NSNumber numberWithDouble: [self getPlayer].currentTime];
                        else
                                progress = [NSNumber numberWithDouble: [progress doubleValue] / 1000.0];
                        if ( (duration == nil) || (duration.class == NSNull.class) )
                                duration = [NSNumber numberWithDouble: [self getDuration] / 1000.0];
                        else
                                duration = [NSNumber numberWithDouble: [duration doubleValue] / 1000.0];
                [self setupNowPlaying: progress duration: duration];
                //[self setUIProgressBar: progress duration: duration];

                long durationLong = [self getDuration];
                [ m_callBack startPlayerCompleted: true duration: durationLong];

        }
        return r;
}



// Give the system information about what the audio player
// is currently playing. Takes in the image to display in the
// notification to control the media playback.
- (void)setupNowPlaying: (NSNumber*) progress duration: (NSNumber*)duration
{
// Progress and duration are in seconds
        NSLog(@"IOS:--> setupNowPlaying");

        // Initialize the MPNowPlayingInfoCenter

         albumArt = nil;
        // The caller specify an asset to be used.
        // Probably good in the future to allow the caller to specify the image itself, and not a resource.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

        if ((m_track.albumArtUrl != nil) && ([m_track.albumArtUrl class] != [NSNull class])   )         // The albumArt is accessed in a URL
        {
                // Retrieve the album art for the
                // current track .
                NSURL* url = [NSURL URLWithString:self ->m_track.albumArtUrl];
                UIImage* artworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
                if(artworkImage)
                {
                        albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
                }
        } else
        if ((m_track.albumArtAsset) && ([m_track.albumArtAsset class] != [NSNull class])   )        // The albumArt is an Asset
        {
                UIImage* artworkImage = [UIImage imageNamed: m_track.albumArtAsset];
                if (artworkImage != nil)
                {
                        albumArt = [ [MPMediaItemArtwork alloc] initWithImage: artworkImage ];

                }
        } else
        if ((m_track.albumArtFile) && ([m_track.albumArtFile class] != [NSNull class])   )          //  The AlbumArt is a File
        {
                UIImage* artworkImage = [UIImage imageWithContentsOfFile: m_track.albumArtFile];
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
#pragma clang diagnostic pop
        [ self setUIProgressBar: progress duration: duration ];
        NSLog(@"IOS:<-- setupNowPlaying");

}


- (void)cleanTarget
{
          NSLog(@"IOS:--> cleanTarget");
          MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

          if (togglePlayPauseTarget != nil)
          {
                [commandCenter.togglePlayPauseCommand removeTarget: togglePlayPauseTarget action: nil];
                togglePlayPauseTarget = nil;
          }

          if (pauseTarget != nil)
          {
                [commandCenter.pauseCommand removeTarget: pauseTarget action: nil];
                pauseTarget = nil;
          }

          if (playTarget != nil)
          {
                [commandCenter.playCommand removeTarget: playTarget action: nil];
                playTarget = nil;
          }

          if (stopTarget != nil)
          {
                [commandCenter.stopCommand removeTarget: stopTarget action: nil];
                stopTarget = nil;
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
 
 
- (void)stop
{
          NSLog(@"IOS:--> stop");
         [self stopTimer];
          if ([self getPlayer] != nil)
          {
                NSLog(@"IOS: !stopPlayer");
                [[self getPlayer] stop];
                [self setPlayer: nil];
          }
          if (m_removeUIWhenStopped)
          {
                [self cleanTarget];
                MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
                [playingInfoCenter setNowPlayingInfo: nil];
                playingInfoCenter.nowPlayingInfo = nil;
          }
          NSLog(@"IOS:<-- stop");
}
 

- (void)stopPlayer
{

          NSLog(@"IOS:--> stopPlayer");
          [self stop];
          [m_callBack stopPlayerCompleted: YES];

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

                togglePlayPauseTarget = [commandCenter.togglePlayPauseCommand addTargetWithHandler:
                ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        NSLog(@"IOS: toggleTarget\n");
                        dispatch_async(dispatch_get_main_queue(),
                        ^{


                                bool b = [[self getPlayer] isPlaying];
                                // If the caller wants to control the pause button, just call him
                                if (b)
                                {
                                        if (self ->m_defaultPauseResume)
                                                [self pausePlayer];
                                        [self ->m_callBack pause];
                                } else
                                {
                                        if ( self ->m_defaultPauseResume)
                                                [self resumePlayer];
                                        [self ->m_callBack resume];
                                }
                        });
                        return MPRemoteCommandHandlerStatusSuccess;
                }];

                pauseTarget = [commandCenter.pauseCommand addTargetWithHandler:
                ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        NSLog(@"IOS: pauseTarget\n");
                        dispatch_async(dispatch_get_main_queue(),
                                ^{
                                        bool b = [[self getPlayer] isPlaying];
                                        if (b)
                                        {
                                                if (self ->m_defaultPauseResume)
                                                        [self pausePlayer];
                                                [self ->m_callBack pause];

                                        }
                                }
                        );
                        return MPRemoteCommandHandlerStatusSuccess;
                 }];

                stopTarget = [commandCenter.stopCommand addTargetWithHandler:
                ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        NSLog(@"IOS: stopTarget\n");
                        return MPRemoteCommandHandlerStatusSuccess;
                }];


                playTarget = [commandCenter.playCommand addTargetWithHandler:
                ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                {
                        NSLog(@"IOS: playTarget\n");
                        dispatch_async(dispatch_get_main_queue(),
                                ^{
                                        bool b = [[self getPlayer] isPlaying];
                                        // If the caller wants to control the pause button, just call him
                                        if (!b)
                                        {
                                                if (self ->m_defaultPauseResume)
                                                        [self resumePlayer];
                                               [self ->m_callBack resume];
                                        }
                                }
                        );

                        return MPRemoteCommandHandlerStatusSuccess;
                }];
        }



        if (canSkipForward)
        {
                forwardTarget = [commandCenter.nextTrackCommand addTargetWithHandler:
                        ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                        {
                                [self ->m_callBack skipForward];
                                return MPRemoteCommandHandlerStatusSuccess;
                        }
                ];
        }

        if (canSkipBackward)
        {
                backwardTarget = [commandCenter.previousTrackCommand addTargetWithHandler:
                        ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event)
                        {
                                [self ->m_callBack skipBackward];
                                return MPRemoteCommandHandlerStatusSuccess;
                        }
                ];
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

       NSLog(@"IOS:<-- setupRemoteCommandCenter");
 }

- (void)setUIProgressBar: (NSNumber*)progress duration: (NSNumber*)duration
{
// Progress and duration are in seconds
        NSLog(@"IOS:--> setUIProgressBar");
        NSMutableDictionary* songInfo = [[NSMutableDictionary alloc] init];
        /*
        if ( (progress == nil) || (progress.class == NSNull.class) )
                progress = [NSNumber numberWithDouble: [self getPlayer].currentTime];
        else
                progress = [NSNumber numberWithDouble: [progress doubleValue] / 1000.0];
        if ( (duration == nil) || (duration.class == NSNull.class) )
                duration = [NSNumber numberWithDouble: [self getDuration] / 1000.0];
        else
                duration = [NSNumber numberWithDouble: [duration doubleValue] / 1000.0];
           */

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

        if (m_track != nil)
        {
                [songInfo setObject: m_track.title forKey: MPMediaItemPropertyTitle];
                [songInfo setObject: m_track.author forKey: MPMediaItemPropertyArtist];
        }
        bool b = [[self getPlayer] isPlaying];
        [songInfo setObject: [NSNumber numberWithDouble:(b ? 1.0f : 0.0f)] forKey: MPNowPlayingInfoPropertyPlaybackRate];


        MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
        [playingInfoCenter setNowPlayingInfo: songInfo];
        NSLog(@"IOS:<-- setUIProgressBar");

}

- (void)updateLockScreenProgression
{
        NSLog(@"IOS:--> updateLockScreenProgression");
        NSNumber* progress = [NSNumber numberWithDouble: [self getPosition]] ;
        NSNumber* duration = [NSNumber numberWithDouble: [self getDuration]];
        [self setUIProgressBar: progress duration: duration];
        NSLog(@"IOS:<-- updateLockScreenProgression");
}



- (void)cleanNowPlaying
{
                MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
                [playingInfoCenter setNowPlayingInfo: nil];
                playingInfoCenter.nowPlayingInfo = nil;

}


- (void)nowPlaying: (FlautoTrack*)track canPause: (bool)canPause canSkipForward: (bool)canSkipForward canSkipBackward: (bool)canSkipBackward
                defaultPauseResume: (bool)defaultPauseResume progress: (NSNumber*)progress duration: (NSNumber*)duration
{
         NSLog(@"IOS:--> nowPlaying");


        [self setupRemoteCommandCenter: canPause canSkipForward: canSkipForward   canSkipBackward: canSkipBackward ];
        if ( !track  )
        {
                [self cleanNowPlaying];
                return;
        }

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
        NSLog(@"IOS:<-- nowPlaying");

}



- (void)seekToPlayer: (long)time;
{

        NSLog(@"IOS:--> seekToPlayer");
        [super seekToPlayer: time];
        [self updateLockScreenProgression];
        NSLog(@"IOS:<-- seekToPlayer");
  }


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
        NSLog(@"IOS:--> audioPlayerDidFinishPlaying");
        if (m_removeUIWhenStopped)
        {
                [self cleanTarget];
                MPNowPlayingInfoCenter* playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
                [playingInfoCenter setNowPlayingInfo: nil];
                playingInfoCenter.nowPlayingInfo = nil;
        }

        [super audioPlayerDidFinishPlaying: player successfully: flag];
        NSLog(@"IOS:<-- audioPlayerDidFinishPlaying");
}

@end
