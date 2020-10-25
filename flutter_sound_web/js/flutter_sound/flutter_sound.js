
//require(["https://cdn.jsdelivr.net/npm/howler@2.1.3/dist/howler.min.js"])
//require ('https://cdn.jsdelivr.net/npm/howler@2.1.3/dist/howler.min.js') ;
function dynamicallyLoadScript(url)
{
        var script = document.createElement("script");  // create a script DOM node
        script.src = url;  // set its src to the provided URL

        document.head.appendChild(script);  // add it to the end of the head section of the page (could change 'head' to 'body' to add it to the end of the body section instead)
}

//dynamicallyLoadScript('https://cdn.jsdelivr.net/npm/howler@2.1.3/dist/howler.min.js');


function playAudioFromBuffer2(dataBuffer)
{
        var audioCtx = new (window.AudioContext || window.webkitAudioContext)();

        // Create an empty three-second stereo buffer at the sample rate of the AudioContext
        var myArrayBuffer = audioCtx.createBuffer(2, audioCtx.sampleRate * 3, audioCtx.sampleRate);
        // Fill the buffer with white noise;
        // just random values between -1.0 and 1.0
        for (var channel = 0; channel < myArrayBuffer.numberOfChannels; channel++)
        {
              // This gives us the actual array that contains the data
              var nowBuffering = myArrayBuffer.getChannelData(channel);
              for (var i = 0; i < myArrayBuffer.length; i++)
              {
                      // Math.random() is in [0; 1.0]
                      // audio needs to be in [-1.0; 1.0]
                      nowBuffering[i] = Math.random() * 2 - 1;
              }
        }

        // Get an AudioBufferSourceNode.
        // This is the AudioNode to use when we want to play an AudioBuffer
        var source = audioCtx.createBufferSource();

        // set the buffer in the AudioBufferSourceNode
        source.buffer = dataBuffer; // myArrayBuffer;

        // connect the AudioBufferSourceNode to the
        // destination so we can hear the sound
        source.connect(audioCtx.destination);

        // start the source playing
        source.start();

}

function playAudioFromBuffer3(dataBuffer)
{
    //var audioData = request.response;

    var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    var source = audioCtx.createBufferSource();
    audioCtx.decodeAudioData
    (
      dataBuffer.buffer,
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

}

/*
var audio;
function playAudioFromURL2(path)
{
      audio= new Howl({
        src: [path]
      });
      audio.play();
}
*/

function playAudioFromURL3(path)
{
        var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        var source = audioCtx.createMediaElementSource(myAudio);

}


class v
{
         static newInstance() { return new Toto();}
         constructor()
          {
          }


          audio;
          playAudioFromURL(path)
          {
            /*
                audio = new Howl({
                  src: [path]
                });
                audio.play();
                */
          }



          startRecorder()
          {
                    var constraints = { audio: true, video: false };
                    navigator.mediaDevices.getUserMedia(constraints).then
                    (function(mediaStream)
                    {
                      /*
                              var audio = document.querySelector('audio');
                              audio.srcObject = mediaStream;
                              audio.onloadedmetadata = function(e)
                              {
                                        audio.play();
                              };
                              */
                              var audioCtx = new AudioContext();
                              var source = audioCtx.createMediaStreamSource(mediaStream);
                              source.connect(audioCtx.destination);

                    })
                    .catch(function(err) { console.log(err.name + ": " + err.message); }); // always check for errors at the end.


          }


          playAudioFromBuffer(dataBuffer)
          {
              //var audioData = request.response;

              var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
              var source = audioCtx.createBufferSource();
              audioCtx.decodeAudioData
              (
                dataBuffer.buffer,
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

}



}
