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

const IS_STOPPED = 0;
const IS_PLAYING = 1;
const IS_PAUSED = 2;

const CB_openAudioSessionCompleted = 0;
const CB_updateProgress = 1;
const CB_pause = 2;
const CB_resume = 3;
const CB_skipBackward = 4;
const CB_skipForward = 5;
const CB_updatePlaybackState = 6;
const CB_needSomeFood = 7;
const CB_audioPlayerFinished = 8;
const CB_startPlayerCompleted = 9;


class FlutterSoundPlayer
{

        static newInstance( aCallback, callbackTable) { return new FlutterSoundPlayer( aCallback, callbackTable);}

        constructor(aCallback, callbackTable)
        {
                this.callback = aCallback;
                this.callbackTable = callbackTable;
                this.howl = null;
                this.temporaryBlob = null;
                this.status = IS_STOPPED;
                this.deltaTime = 0;
                this.subscriptionDuration = 0;
                this.duration = 0;
        }

        initializeMediaPlayer( focus, category, mode, audioFlags, device, withUI)
        {
                //this.callback.openAudioSessionCompleted(true);
                this.callbackTable[CB_openAudioSessionCompleted](this.callback, true);
                return this.getPlayerState();
        }

        releaseMediaPlayer()
        {
                return this.getPlayerState();
        }

        playAudioFromURL(path, codec)
        {

                console.log('playAudioFromURL : ' + path);
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
                                if (me.getPlayerState() == IS_PLAYING) // And not IS_PAUSED
                                {
                                        me.callbackTable[CB_startPlayerCompleted](me.callback, me.duration);

                                }
                                me.status = IS_PLAYING;
                                //me.deltaTime = 0;
                                me.startTimer();

                         },

                        onplayerror: function()
                        {
                               console.log('onplayerror');
                               me.stopPlayer();
                        },

                        onend: function()
                        {
                               console.log('onend');
                               me.stopPlayer();
                               me.callbackTable[CB_audioPlayerFinished](me.callback, me.getPlayerState());
                        },

                        onloaderror: function()
                        {
                               console.log('onloaderror');
                               me.stopPlayer()
                        },

                        onpause: function()
                        {
                               console.log('onpause');
                        },

                        onstop: function()
                        {
                               console.log('onstop');
                               me.status = IS_STOPPED;
                               me.howl = null;
                        },

                        onseek: function()
                        {
                               //console.log('onseek');
                        },
               });

                this.howl = howl;
                howl.play();
                //this.callback.startPlayerCompleted(howl.duration());
                this.status = IS_PLAYING; // Not very good : in fact the player is not really yet playing
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

        startPlayer( codec, fromDataBuffer,  fromURI, numChannels, sampleRate)
        {
                this.stopPlayer();
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

                } else
                if (fromURI != null && fromURI != '')
                {
                        var data = window.sessionStorage.getItem(fromURI);
                        if (data == null)
                        {
                                data = window.localStorage.getItem(fromURI);
                        }
                        if (data != null)
                        {
                                console.log('startPlayer : ' + data.constructor.name);
                                fromURI = data;
                        }
                }
                this.deltaTime = 0;
                this.playAudioFromURL(fromURI, codec);
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

        stopPlayer()
        {
                this.stopTimer();

                if (this.howl != null)
                        this.howl.stop();

                if (this.temporaryBlob != null)
                        URL.revokeObjectURL(this.temporaryBlob);
                this.temporaryBlob = null;

                this.status = IS_STOPPED;
                return this.getPlayerState();
        }

        getPlayerState()
        {
                if (this.howl == null)
                {
                        this.status = IS_STOPPED;
                }
                return this.status;
         }

        pausePlayer()
        {
                this.stopTimer();

                if (this.getPlayerState() == IS_PLAYING)
                {
                        this.status = IS_PAUSED;
                        this.howl.pause();
                }
                return this.getPlayerState();
        }

        resumePlayer()
        {
                if (this.getPlayerState() == IS_PAUSED)
                {
                        this.howl.play();
                }
                return IS_PLAYING; // Not good. In fact, it is not yet playing
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
                console.log('startTimer()');
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
