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


const PLAYER_VERSION = '8.2.0'

function newPlayerInstance(aCallback, callbackTable) { return new FlutterSoundPlayer(aCallback, callbackTable); }

const IS_PLAYER_STOPPED = 0;
const IS_PLAYER_PLAYING = 1;
const IS_PLAYER_PAUSED = 2;

const CB_updateProgress = 0;
const CB_updatePlaybackState = 1;
const CB_needSomeFood = 2;
const CB_audioPlayerFinished = 3;
const CB_startPlayerCompleted = 4;
const CB_pausePlayerCompleted = 5;
const CB_resumePlayerCompleted = 6;
const CB_stopPlayerCompleted = 7;
const CB_openPlayerCompleted = 8;
const CB_closePlayerCompleted = 9;
const CB_player_log = 10;

var instanceNumber = 1;

class FlutterSoundPlayer {

        static newInstance(aCallback, callbackTable) { return new FlutterSoundPlayer(aCallback, callbackTable); }

        constructor(aCallback, callbackTable) {
                this.callback = aCallback;
                this.callbackTable = callbackTable;
                this.howl = null;
                this.temporaryBlob = null;
                this.status = IS_PLAYER_STOPPED;
                //this.deltaTime = 0;
                this.subscriptionDuration = 0;
                this.duration = 0;
                this.instanceNo = instanceNumber;
                this.callbackTable[CB_player_log](this.callback, DBG, 'Instance Number : ' + this.instanceNo.toString())
                ++instanceNumber;
        }

        initializeMediaPlayer(focus, category, mode, audioFlags, device, withUI) {
                //this.callback.openAudioSessionCompleted(true);
                this.status = IS_PLAYER_STOPPED;
                this.callbackTable[CB_openPlayerCompleted](this.callback, this.getPlayerState(), true);
                return this.getPlayerState();
        }

        releaseMediaPlayer() {
                this.status = IS_PLAYER_STOPPED;
                this.callbackTable[CB_closePlayerCompleted](this.callback, this.getPlayerState(), true);
                return this.getPlayerState();
        }



        playAudioFromURL(path, codec) {

                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: ---> playAudioFromURL : ' + path);
                var me = this;
                var howl = new Howl
                        ({
                                src: [path],
                                format: tabFormat[codec],

                                onload: function () {
                                        me.callbackTable[CB_player_log](me.callback, DBG, 'onload');
					me.howl.play();
                                },

                                onplay: function () {
                                        me.callbackTable[CB_player_log](me.callback, DBG, 'onplay');
                                        me.duration = Math.ceil(howl.duration() * 1000);
                                        me.status = IS_PLAYER_PLAYING;
                                        if (me.pauseResume != IS_PLAYER_PAUSED) {
                                                me.callbackTable[CB_startPlayerCompleted](me.callback, me.getPlayerState(), true, me.duration); // Duration is unknown

                                        } else {
                                                me.callbackTable[CB_resumePlayerCompleted](me.callback, me.getPlayerState(), true);

                                        }
                                        me.startTimer();

                                },

                                onplayerror: function () {
                                        me.callbackTable[CB_player_log](me.callback, ERROR, 'onplayerror');
                                        me.stop();
                                },

                                onend: function () {
                                        me.callbackTable[CB_player_log](me.callback, DBG, 'onend');
                                        me.stop();
                                        me.status = IS_PLAYER_STOPPED;
                                        me.callbackTable[CB_audioPlayerFinished](me.callback, me.getPlayerState());
                                },

                                onloaderror: function () {
                                        me.callbackTable[CB_player_log](me.callback, ERROR, 'onloaderror');
                                        me.stop()
                                },

                                onpause: function () {
                                        me.callbackTable[CB_player_log](me.callback, DBG, 'onpause');
                                        me.status = IS_PLAYER_PAUSED;
                                        me.callbackTable[CB_pausePlayerCompleted](me.callback, me.getPlayerState(), true);

                                },

                                onstop: function () {
                                        me.callbackTable[CB_player_log](me.callback, DBG, 'onstop');
                                        me.status = IS_PLAYER_STOPPED;
                                        me.howl = null;
                                        me.callbackTable[CB_stopPlayerCompleted](me.callback, me.getPlayerState(), true);
                                },

                                onseek: function () {
                                        //me.callbackTable[CB_player_log](me.callback, DBG, 'onseek');
                                },
                        });

                this.howl = howl;
                if (this.latentVolume != null && this.latentVolume >= 0)
                        this.howl.volume(this.latentVolume);
                if (this.latentSpeed != null && this.latentSpeed >= 0)
                        this.howl.rate(this.latentSpeed);
                if (this.latentSeek != null && this.latentSeek >= 0)
                        this.seekToPlayer(this.latentSeek);
                this.pauseResume = IS_PLAYER_PLAYING;
                // howl.play(); // This now done in 'onload'
                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: <--- playAudioFromURL');
                return this.getPlayerState();
        }


        /* ACTUALLY NOT USED
                playAudioFromBuffer(dataBuffer) // Actually not used
                {
        
                        var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
                        var source = audioCtx.createBufferSource();
                        me.callbackTable[CB_player_log](me.callback, DBG, dataBuffer.constructor.name)
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
                                function(e){ me.callbackTable[CB_player_log](me.callback, DBG, "Error with decoding audio data" + e.err); }
                        );
                        this.callback.startPlayerCompleted(777);
                        return 0; // playAudioFromBuffer() does not support sound Duration
        }
        */




        setAudioFocus(focus, category, mode, audioFlags, device,) {
                return this.getPlayerState();
        }


        isDecoderSupported(codec,) {
                return true; // TODO
        }

        setSubscriptionDuration(duration) {
                this.callbackTable[CB_player_log](this.callback, DBG, 'setSubscriptionDuration');
                this.subscriptionDuration = duration;
                if (duration > 0 && this.howl != null)
                        this.startTimer();
                return this.getPlayerState();
        }


        getRecordURL(path,) {
                var myStorage;
                if ((path == null) || (path == '')) {
                        return null;
                }
                if (path.includes("/"))
                        return path;
                if (path.substring(0, 1) == '/') {
                        myStorage = window.localStorage;
                        this.callbackTable[CB_player_log](this.callback, DBG, 'localStorage');
                } else {
                        myStorage = window.sessionStorage;
                        this.callbackTable[CB_player_log](this.callback, DBG, 'sessionStorage');
                }

                var url = myStorage.getItem(path);
                return url

        }

        startPlayer(codec, fromDataBuffer, fromURI, numChannels, sampleRate) {
                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: ---> startPlayer');
                this.stop();
                if (this.temporaryBlob != null) {
                        URL.revokeObjectURL(this.temporaryBlob);
                        this.temporaryBlob = null;
                }
                if (fromDataBuffer != null) {
                        this.callbackTable[CB_player_log](this.callback, DBG, 'startPlayer : ' + fromDataBuffer.constructor.name);
                        var anArray = [fromDataBuffer]; // new Array(fromDataBuffer);
                        // return this.playAudioFromBuffer(fromDataBuffer.buffer); // playAudioFromBuffer() is ctually not used
                        var blob = new Blob(anArray, { 'type': mime_types[codec] });
                        fromURI = URL.createObjectURL(blob);
                        this.temporaryBlob = fromURI;

                }
                if (fromURI == null || fromURI == '') {
                        fromURI = lastUrl;
                        this.callbackTable[CB_player_log](this.callback, DBG, 'Playing lastUrl : ' + lastUrl);
                }

                this.callbackTable[CB_player_log](this.callback, DBG, 'startPlayer : ' + fromURI);
                var url = this.getRecordURL(fromURI);

                if (url != null) {
                        this.callbackTable[CB_player_log](this.callback, DBG, 'startPlayer : ' + url.constructor.name);
                        fromURI = url;
                }
                //this.deltaTime = 0;
                this.pauseResume = IS_PLAYER_PLAYING; // Maybe too early
                this.playAudioFromURL(url, codec);
                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: <--- startPlayer');
                return this.getPlayerState();
        }

        feed(data,) {
                return this.getPlayerState();
        }

        startPlayerFromTrack(progress, duration, track, canPause, canSkipForward, canSkipBackward, defaultPauseResume, removeUIWhenStopped,) {
                return 0; // TODO
        }

        nowPlaying(progress, duration, track, canPause, canSkipForward, canSkipBackward, defaultPauseResume,) {
                return this.getPlayerState();
        }

        stop() {
                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: ---> stop');
                this.stopTimer();


                if (this.temporaryBlob != null)
                        URL.revokeObjectURL(this.temporaryBlob);
                this.temporaryBlob = null;

                if (this.howl != null) {
                        this.howl.stop();
                        this.callbackTable[CB_player_log](this.callback, DBG, 'JS: <--- stop');
                        return true;
                }
                else {
                        this.status = IS_PLAYER_STOPPED; // Maybe too early ?
                        //this.callbackTable[CB_stopPlayerCompleted](this.callback,  IS_PLAYER_STOPPED, true);
                        this.callbackTable[CB_player_log](this.callback, DBG, 'JS: <--- stop');
                        return false;
                }

        }

        stopPlayer() {
                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: ---> stopPlayer');
                //if (this.howl == null)
                //this.callbackTable[CB_stopPlayerCompleted](this.callback,  IS_PLAYER_STOPPED, true);
                if (!this.stop())
                        this.callbackTable[CB_stopPlayerCompleted](this.callback, this.getPlayerState(), true);
                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: <--- stopPlayer');
                return this.getPlayerState();
        }

        getPlayerState() {
                if (this.howl == null) {
                        this.status = IS_PLAYER_STOPPED;
                }
                return this.status;
        }

        pausePlayer() {
                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: ---> pausePlayer');
                this.stopTimer();

                if (this.getPlayerState() == IS_PLAYER_PLAYING) {
                        //this.status = IS_PLAYER_PAUSED; // Maybe too early
                        this.howl.pause();
                } else {
                        this.callbackTable[CB_pausePlayerCompleted](this.callback, this.getPlayerState(), false);
                }

                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: <--- pausePlayer');
                return this.getPlayerState();
        }

        resumePlayer() {
                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: ---> resumePlayer');
                if (this.getPlayerState() == IS_PLAYER_PAUSED) {
                        //this.status = IS_PLAYER_PLAYING; // Maybe too early
                        this.pauseResume = IS_PLAYER_PAUSED;
                        this.howl.play();
                } else {
                        this.callbackTable[CB_resumePlayerCompleted](this.callback, this.getPlayerState(), false);
                }
                this.startTimer();

                this.callbackTable[CB_player_log](this.callback, DBG, 'JS: <--- resumePlayer');
                return this.getPlayerState();
        }

        seekToPlayer(duration) {
                this.callbackTable[CB_player_log](this.callback, DBG, '---> seekToPlayer()');
                if (this.howl != null) {
                        this.latentSeek = 0;
                        this.countDownDate = new Date().getTime() - duration;
                        //this.deltaTime = 0;
                        this.howl.seek(duration / 1000);
                } else
                        this.latentSeek = duration;
                this.callbackTable[CB_player_log](this.callback, DBG, '<--- seekToPlayer()');
                return this.getPlayerState();
        }

        setVolume(volume) {
                this.callbackTable[CB_player_log](this.callback, DBG, '---> setVolume()');
                this.latentVolume = volume;
                if (this.howl != null)
                        this.howl.volume(volume);
                this.callbackTable[CB_player_log](this.callback, DBG, '<--- setVolume()');
                return this.getPlayerState();
        }


        setSpeed(speed) {
                this.callbackTable[CB_player_log](this.callback, DBG, '---> setSpeed()');
                this.latentSpeed = speed;
                if (this.howl != null)
                        this.howl.rate(speed);
                this.callbackTable[CB_player_log](this.callback, DBG, '<--- setSpeed()');
                return this.getPlayerState();
        }

        setUIProgressBar(duration, progress) {
                return this.getPlayerState();
        }


        startTimer() {
                this.callbackTable[CB_player_log](this.callback, DBG, '---> startTimer()');
                this.stopTimer();
                var me = this;

                if (this.subscriptionDuration > 0) {
                        this.countDownDate = new Date().getTime();
                        this.timerId = setInterval
                                (
                                        function () {
                                                //var now = new Date().getTime();
                                                //var distance = now - me.countDownDate;
                                                //distance += me.deltaTime;
                                                var pos = Math.floor(me.howl.seek() * 1000);
                                                if (pos > me.duration)
                                                        pos = me.duration;
                                                me.callbackTable[CB_updateProgress](me.callback, pos/*me.deltaTime + distance*/, me.duration);

                                        },
                                        this.subscriptionDuration
                                );
                }
                this.callbackTable[CB_player_log](this.callback, DBG, '<--- startTimer()');
        }

        stopTimer() {
                this.callbackTable[CB_player_log](this.callback, DBG, 'stopTimer()');
                if (this.timerId != null) {
                        clearInterval(this.timerId);
                        //var now = new Date().getTime();
                        //var distance = now - this.countDownDate;
                        //this.deltaTime += distance;
                        this.timerId = null;
                }
        }

}
