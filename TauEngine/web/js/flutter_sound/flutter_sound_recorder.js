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



function newRecorderInstance(caller) { var x = new FlutterSoundRecorder(); x.caller = caller; return x;}



class FlutterSoundRecorder
{
        static newInstance(caller) {  var x = new FlutterSoundRecorder(); x.caller = caller; return x;}

        constructor(caller)
        {
                this.caller = caller;
        }



        initializeFlautoRecorder( aCallback, focus, category, mode, audioFlags, device)
        {
               this.callback = aCallback;

        }


        releaseMediaPlayer()
        {

        }


        setAudioFocus( focus, category, mode, audioFlags, device)
        {

        }


        isEncoderSupported( codec)
        {

                for (var i in mime_types)
                {
                        console.log( "Is " + mime_types[i] + " supported? " + (MediaRecorder.isTypeSupported(mime_types[i]) ? "Maybe!" : "Nope :("));
                }

               return MediaRecorder.isTypeSupported(mime_types[codec]);
        }


        setSubscriptionDuration( duration)
        {

        }


        startRecorder( path, sampleRate, numChannels, bitRate, codec, toStream, audioSource, onStop)
        {
                var constraints = { audio: true};
                var chunks ;//= [];
                var me = this;
                var myStorage;
                if ((path != null) && (path != ''))
                {
                        if (path.substring(0,1) == '_')
                        {
                                myStorage = window.sessionStorage;
                                console.log('sessionStorage');
                        } else
                        {
                                myStorage = window.localStorage;
                                console.log('localStorage'); // Actually we do not use 'sessionStorage'
                                //console.log('sessionStorage');
                       }
                }


                //var myStorage = myStorage = window.sessionStorage;

                navigator.mediaDevices.getUserMedia(constraints).then
                (function(mediaStream)
                {
                        /*
                        {
                                var audioCtx = new AudioContext();


                                var source = audioCtx.createMediaStreamSource(mediaStream);

                                var offlineCtx = new OfflineAudioContext(2,44100*40,44100);
                                var sourceOfflineCtx = offlineCtx.createBufferSource();
                                //source.connect(sourceOfflineCtx);
                                //source.connect(offlineCtx.source);
                                //source.start();
                                offlineCtx.startRendering().then(function(renderedBuffer)
                                {
                                        console.log('Rendering completed successfully');
                                        console.log('++++++++++' + renderedBuffer.constructor.name);
                                        //this.caller.toto(chunks);
                                        onStop(renderedBuffer);
                                        console.log('toto done');


                                }
                                ).catch(function(err)
                                {
                                        console.log('Rendering failed: ' + err);
          // Note: The promise should reject when startRendering is called a second time on an OfflineAudioContext
                                }
                                );
                        }
                );
        }
*/

                        //       var buffer = audioCtx.createBuffer(numChannels, tenMinutes, sampleRate); // Play back ???
                        //      source.connect(audioCtx.destination); // This ouput to speaker // TODO : not yet supported


                        // ===========================================================================
                        //var audioCtx = new AudioContext();
                        //var dest = new audioCtx.createMediaStreamDestination(); // osc
                        var chunks = [];
                        var options =
                        {
                              audioBitsPerSecond : bitRate,
                              mimeType : mime_types[codec] //'audio/ogg; codecs=opus'
                        }




                        var mediaRecorder = new MediaRecorder(mediaStream, options);
                        me.mediaRecorder = mediaRecorder;
                        if (toStream)
                                mediaRecorder.start(30); // 30 milliseconds for a chunk
                        else
                                mediaRecorder.start();
                        console.log(mediaRecorder.state);
                        console.log("recorder started");


                        mediaRecorder.ondataavailable = function(e)
                        {
                                if (toStream)
                                {
                                        me.callback.recordingData(e.data);
                                }
                                if (path != null && path != '')
                                {
                                        //chunks.push(e.data);
                                        //chunks = e.data;
                                        console.log('++++++++++' + e.data.constructor.name);
                                        //e.data.arrayBuffer().then(buffer => chunks = buffer);
                                        chunks.push(e.data);

                                }
                        }

                        mediaRecorder.onstop = function(e)
                        {

                                //var clipName = prompt('Enter a name for your sound clip');

                                //var clipContainer = document.createElement('article');
                                //var clipLabel = document.createElement('p');
                                //var audio = document.createElement('audio');
                                //var deleteButton = document.createElement('button');

                                //clipContainer.classList.add('clip');
                                //audio.setAttribute('controls', '');
                                //deleteButton.innerHTML = "Delete";
                                //clipLabel.innerHTML = clipName;

                                //clipContainer.appendChild(audio);
                                //clipContainer.appendChild(clipLabel);
                                //clipContainer.appendChild(deleteButton);
                                //soundClips.appendChild(clipContainer);

                                //audio.controls = true;
                                if (path != null && path != '')
                                {
                                        //var blob = new Blob(chunks, { 'type' : 'audio/ogg; codecs=opus' });
                                        console.log("data available after in Storage : " + path);
                                        //console.log("caller = " + caller.constructor.name);
                                        console.log('++++++++++' + chunks.constructor.name);
                                        var blob = new Blob(chunks, {'type' : "audio/webm\;codecs=opus"} /* { 'type' : 'audio/ogg; codecs=opus' }*/);
                                        var url = URL.createObjectURL(blob);
                                        console.log('!!!!!!!!!!' + url.constructor.name);
                                        onStop(url);
                                        myStorage.setItem(path, url);
/*
                                        var xhr = new XMLHttpRequest();
                                        var blob;
                                        var fileReader = new FileReader();
                                        xhr.open("GET", url, true);
                                        xhr.responseType = "arraybuffer";


                                        xhr.addEventListener("load", function ()
                                        {
                                                if (xhr.status === 200)
                                                {
                                                        // Create a blob from the response
                                                        blob = new Blob([xhr.response], {type: "audio/webm\;codecs=opus"});

                                                        // onload needed since Google Chrome doesn't support addEventListener for FileReader
                                                        fileReader.onload = function (evt)
                                                        {
                                                                // Read out file contents as a Data URL
                                                                var result = evt.target.result;
                                                                // Set image src to Data URL
                                                                //rhino.setAttribute("src", result);
                                                                // Store Data URL in localStorage
                                                                try
                                                                {
                                                                        //localStorage.setItem("rhino", result);
                                                                        onStop(result);
                                                                        myStorage.setItem(path, JSON.stringify(result));
                                                                } catch (e)
                                                                {
                                                                        console.log("Storage failed: " + e);
                                                                }
                                                        };
                                                        // Load blob as Data URL
                                                        fileReader.readAsDataURL(blob);
                                                }
                                        }, false);
                                        // Send XHR
                                        xhr.send();
*/


                                        //this.caller.toto(chunks);
                                        //onStop(url);
                                        console.log('toto done');
                                        //chunks.arrayBuffer().then(buffer => myStorage.setItem(path, buffer));

                                        //myStorage.setItem(path, JSON.stringify(chunks));
                                        //myStorage.setItem(path, chunks);
                                }
                                //chunks = null;///[];
                                        //var audioURL = URL.createObjectURL(blob);
                                //audio.src = audioURL;
                                console.log("recorder stopped");

                                //deleteButton.onclick = function(e)
                                //{
                                        //evtTgt = e.target;
                                        //evtTgt.parentNode.parentNode.removeChild(evtTgt.parentNode);
                                //}
                        }


                });
                //.catch(function(err) { console.log(err.name + ": " + err.message); }); // always check for errors at the end.
        }

        stopRecorder()
        {
                if (this.mediaRecorder != null)
                {
                        this.mediaRecorder.stop();
                        console.log(this.mediaRecorder.state);
                }
                console.log("recorder stopped");
                this.mediaRecorder = null;
        }


        pauseRecorder()
        {
                this.mediaRecorder.pause();
                console.log(this.mediaRecorder.state);
                console.log("recorder paused");

        }


        resumeRecorder()
        {
                this.mediaRecorder.resume();
                console.log(this.mediaRecorder.state);
                console.log("recorder resumed");
        }


}
