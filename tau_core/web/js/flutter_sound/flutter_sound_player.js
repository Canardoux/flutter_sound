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




function newPlayerInstance(aCallback, callbackTable) { return new FlutterSoundPlayer(aCallback, callbackTable);}

const IS_PLAYER_STOPPED = 0;
const IS_PLAYER_PLAYING = 1;
const IS_PLAYER_PAUSED = 2;

const CB_updateProgress = 0;
const CB_pause = 1;
const CB_resume = 2;
const CB_skipBackward = 3;
const CB_skipForward = 4;
const CB_updatePlaybackState = 5;
const CB_needSomeFood = 6;
const CB_audioPlayerFinished = 7;
const CB_startPlayerCompleted = 8;
const CB_pausePlayerCompleted = 9;
const CB_resumePlayerCompleted = 10;
const CB_stopPlayerCompleted = 11;
const CB_openPlayerCompleted = 12;
const CB_closePlayerCompleted = 13;


class FlutterSoundPlayer
{

        static newInstance( aCallback, callbackTable) { return new FlutterSoundPlayer( aCallback, callbackTable);}

        constructor(aCallback, callbackTable)
        {
                this.callback = aCallback;
                this.callbackTable = callbackTable;
                this.howl = null;
                this.temporaryBlob = null;
                this.status = IS_PLAYER_STOPPED;
                this.deltaTime = 0;
                this.subscriptionDuration = 0;
                this.duration = 0;
                this.instanceNo = instanceNumber;
                console.log('Instance Number : ' + this.instanceNo.toString())
                ++instanceNumber;
        }

        initializeMediaPlayer( focus, category, mode, audioFlags, device, withUI)
        {
                //this.callback.openAudioSessionCompleted(true);
                this.status = IS_PLAYER_STOPPED;
                this.callbackTable[CB_openPlayerCompleted](this.callback,  IS_PLAYER_STOPPED, true);
                return this.getPlayerState();
        }

        releaseMediaPlayer()
        {
                this.status = IS_PLAYER_STOPPED;
                this.callbackTable[CB_closePlayerCompleted](this.callback,  IS_PLAYER_STOPPED, true);
                return this.getPlayerState();
        }



        playAudioFromURL(path, codec)
        {

                console.log( 'JS: ---> playAudioFromURL : ' + path);
                var me = this;
                var howl = new Howl
                ({
                        src: [path],
                        format: tabFormat[codec],

                        onload: function()
                        {
                                console.log('onload');
                        },

                        onplay: function()
                        {
                                console.log('onplay');
                                me.duration = Math.ceil(howl.duration() * 1000);
                                //var stat = me.getPlayerState();
                                //console.log('status = ' + stat);
                                me.status = IS_PLAYER_PLAYING;
                                if (me.pauseResume != IS_PLAYER_PAUSED) // And not IS_PLAYER_PAUSED
                                {
                                        me.callbackTable[CB_startPlayerCompleted](me.callback, IS_PLAYER_PLAYING, true, me.duration); // Duration is unknown

                                } else
                                {
                                        me.callbackTable[CB_resumePlayerCompleted](me.callback, IS_PLAYER_PLAYING, true);

                                }
                                //me.deltaTime = 0;
                                me.startTimer();

                         },

                        onplayerror: function()
                        {
                               console.log('onplayerror');
                               me.stop();
                        },

                        onend: function()
                        {
                               console.log('onend');
                               //me.howl = null;
                               me.stop();
                               me.status = IS_PLAYER_STOPPED;
                               me.callbackTable[CB_audioPlayerFinished](me.callback, me.getPlayerState());
                        },

                        onloaderror: function()
                        {
                               console.log('onloaderror');
                               me.stop()
                        },

                        onpause: function()
                        {
                               console.log('onpause');
                               me.status = IS_PLAYER_PAUSED;
                               me.callbackTable[CB_pausePlayerCompleted](me.callback,  IS_PLAYER_PAUSED, true);

                        },

                        onstop: function()
                        {
                               console.log('onstop');
                               me.status = IS_PLAYER_STOPPED;
                               me.howl = null;
                               me.callbackTable[CB_stopPlayerCompleted](me.callback,  IS_PLAYER_STOPPED, true);
                       },

                        onseek: function()
                        {
                               //console.log('onseek');
                        },
               });

                this.howl = howl;
                this.pauseResume = IS_PLAYER_PLAYING;
                howl.play();
                //this.callback.startPlayerCompleted(howl.duration());
                //!!!!!!!!!!!!!this.status = IS_PLAYER_PLAYING; // Not very good : in fact the player is not really yet playing
                console.log( 'JS: <--- playAudioFromURL');
                return this.getPlayerState();
        }


/* ACTUALLY NOT USED
        playAudioFromBuffer(dataBuffer) // Actually not used
        {

                var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
                var source = audioCtx.createBufferSource();
                console.log(dataBuffer.constructor.name)
                audioCtx.decodeAudioData
                (
                        dataBuffer, //dataBuffer.buffer,
                        function(buffer)
                        {
                                source.buffer = buffer;

                                source.connect(audioCtx.destination);
                                source.loop = false;
                                   // start the source playing
                                source.start();
                        },
                        function(e){ console.log("Error with decoding audio data" + e.err); }
                );
                this.callback.startPlayerCompleted(777);
                return 0; // playAudioFromBuffer() does not support sound Duration
}
*/




        setAudioFocus( focus, category, mode, audioFlags, device,)
        {
                return this.getPlayerState();
        }


        isDecoderSupported( codec,)
        {
                return true;
        }

        setSubscriptionDuration( duration)
        {
                console.log( 'setSubscriptionDuration');
                this.subscriptionDuration = duration;
                return this.getPlayerState();
        }


        getRecordURL(path,)
        {
                var myStorage;
                if ((path == null) || (path == ''))
                {
                        return null;
                }
                if ( path.includes("/") )
                    return path;
                if (path.substring(0,1) == '/')
                {
                        myStorage = window.localStorage;
                        console.log('localStorage');
                } else
                {
                        myStorage = window.sessionStorage;
                        console.log('sessionStorage');
                }

                var url = myStorage.getItem(path);
                return url

        }

        startPlayer( codec, fromDataBuffer,  fromURI, numChannels, sampleRate)
        {
                console.log( 'JS: ---> startPlayer');
                this.stop();
                if (this.temporaryBlob != null)
                {
                        URL.revokeObjectURL(this.temporaryBlob);
                        this.temporaryBlob = null;
                }
                if (fromDataBuffer != null)
                {
                        console.log('startPlayer : ' + fromDataBuffer.constructor.name);
                        var anArray =  [fromDataBuffer]; // new Array(fromDataBuffer);
                        // return this.playAudioFromBuffer(fromDataBuffer.buffer); // playAudioFromBuffer() is ctually not used
                        var blob = new Blob(anArray, {'type' : mime_types[codec]} );
                        fromURI = URL.createObjectURL(blob);
                        this.temporaryBlob = fromURI;

                }
                if (fromURI == null || fromURI == '')
                {
                        fromURI = lastUrl;
                        console.log('Playing lastUrl : ' + lastUrl);
                }

                console.log('startPlayer : ' + fromURI);
                var url = this.getRecordURL(fromURI);

                if (url != null)
                {
                        console.log('startPlayer : ' + url.constructor.name);
                        fromURI = url;
                }
                this.deltaTime = 0;
                this.pauseResume = IS_PLAYER_PLAYING; // Maybe too early
                this.playAudioFromURL(url, codec);
                console.log( 'JS: <--- startPlayer');
                return this.getPlayerState();
        }

        feed( data,)
        {
                return this.getPlayerState();
        }

        startPlayerFromTrack( progress, duration, track, canPause, canSkipForward, canSkipBackward, defaultPauseResume, removeUIWhenStopped, )
        {
                return 0; // TODO
        }

        nowPlaying( progress, duration, track, canPause, canSkipForward, canSkipBackward, defaultPauseResume, )
        {
                return this.getPlayerState();
        }

        stop()
        {
                console.log( 'JS: ---> stop');
               this.stopTimer();


                if (this.temporaryBlob != null)
                        URL.revokeObjectURL(this.temporaryBlob);
                this.temporaryBlob = null;

                if (this.howl != null)
                {
                        this.howl.stop();
                        console.log( 'JS: <--- stop');
                        return true;
                }
                else
                {
                        this.status = IS_PLAYER_STOPPED; // Maybe too early ?
                        //this.callbackTable[CB_stopPlayerCompleted](this.callback,  IS_PLAYER_STOPPED, true);
                        console.log( 'JS: <--- stop');
                        return false;
                }

        }

        stopPlayer()
        {
                console.log( 'JS: ---> stopPlayer');
                //if (this.howl == null)
                        //this.callbackTable[CB_stopPlayerCompleted](this.callback,  IS_PLAYER_STOPPED, true);
                if (!this.stop())
                        this.callbackTable[CB_stopPlayerCompleted](this.callback,  IS_PLAYER_STOPPED, true);
                console.log( 'JS: <--- stopPlayer');
                return this.getPlayerState();
        }

        getPlayerState()
        {
                if (this.howl == null)
                {
                        this.status = IS_PLAYER_STOPPED;
                }
                return this.status;
         }

        pausePlayer()
        {
                console.log( 'JS: ---> pausePlayer');
                this.stopTimer();

                if (this.getPlayerState() == IS_PLAYER_PLAYING)
                {
                        //this.status = IS_PLAYER_PAUSED; // Maybe too early
                        this.howl.pause();
                } else
                {
                        this.callbackTable[CB_pausePlayerCompleted](this.callback,  this.getPlayerState(), false);
                }

                console.log( 'JS: <--- pausePlayer');
                 return this.getPlayerState();
        }

        resumePlayer()
        {
                console.log( 'JS: ---> resumePlayer');
                if (this.getPlayerState() == IS_PLAYER_PAUSED)
                {
                        //this.status = IS_PLAYER_PLAYING; // Maybe too early
                        this.pauseResume = IS_PLAYER_PAUSED;
                        this.howl.play();
                } else
                {
                        this.callbackTable[CB_resumePlayerCompleted](this.callback,  this.getPlayerState(), false);
                }


                console.log( 'JS: <--- resumePlayer');
                return this.getPlayerState();
        }

        seekToPlayer(  duration)
        {
                this.countDownDate = new Date().getTime() - duration;
                this.deltaTime = 0;
                this.howl.seek(duration / 1000);
                return this.getPlayerState();
        }

        setVolume( volume)
        {
                this.howl.volume(volume);
                return this.getPlayerState();
        }

        setUIProgressBar( duration,  progress)
        {
                return this.getPlayerState();
        }


        startTimer()
        {
                console.log('---> startTimer()');
                this.stopTimer();
                var me = this;

                if (this.subscriptionDuration > 0)
                {
                        this.countDownDate = new Date().getTime();
                        this.timerId = setInterval
                        (
                                function()
                                {
                                        var now = new Date().getTime();
                                        var distance = now - me.countDownDate;
                                        me.callbackTable[CB_updateProgress](me.callback, me.deltaTime + distance, me.duration);

                                },
                                this.subscriptionDuration
                        );
                }
                console.log('<--- startTimer()');
        }

        stopTimer()
        {
                console.log('stopTimer()');
                if (this.timerId != null)
                {
                        clearInterval(this.timerId);
                        var now = new Date().getTime();
                        var distance = now - this.countDownDate;
                        this.deltaTime += distance;
                        this.timerId = null;
                }
        }

}
